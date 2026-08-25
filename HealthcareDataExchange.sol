// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HealthcareDataExchange {

    enum Role {
        None,
        Patient,
        Doctor,
        Hospital
    }

    struct User {
        address account;
        string name;
        Role role;
        bool registered;
    }

    struct MedicalRecord {
        uint256 recordId;
        address patient;
        address uploadedBy;
        string documentType;
        string metadata;
        string documentHash;
        uint256 createdAt;
        bool active;
    }

    struct AccessPermission {
        bool granted;
        uint256 grantedAt;
        uint256 revokedAt;
    }

    address public admin;
    uint256 private nextRecordId = 1;

    mapping(address => User) public users;
    mapping(uint256 => MedicalRecord) public records;

    mapping(
        uint256 => mapping(address => AccessPermission)
    ) public permissions;

    mapping(address => uint256[]) private patientRecords;

    event UserRegistered(
        address indexed account,
        Role role
    );

    event RecordCreated(
        uint256 indexed recordId,
        address indexed patient,
        address indexed uploadedBy,
        string documentType,
        string documentHash
    );

    event AccessRequested(
        uint256 indexed recordId,
        address indexed requester
    );

    event AccessGranted(
        uint256 indexed recordId,
        address indexed patient,
        address indexed grantedTo
    );

    event AccessRevoked(
        uint256 indexed recordId,
        address indexed patient,
        address indexed revokedFrom
    );

    event RecordAccessed(
        uint256 indexed recordId,
        address indexed accessor,
        uint256 timestamp
    );

    event HashVerified(
        uint256 indexed recordId,
        address indexed verifier,
        bool valid
    );

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "Only admin can perform this action"
        );
        _;
    }

    modifier onlyRegistered() {
        require(
            users[msg.sender].registered,
            "User is not registered"
        );
        _;
    }

    modifier onlyPatient() {
        require(
            users[msg.sender].role == Role.Patient,
            "Only patient can perform this action"
        );
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // ==============================
    // USER REGISTRATION
    // ==============================

    function registerPatient(
        string memory _name
    ) external {

        require(
            !users[msg.sender].registered,
            "User already registered"
        );

        users[msg.sender] = User(
            msg.sender,
            _name,
            Role.Patient,
            true
        );

        emit UserRegistered(
            msg.sender,
            Role.Patient
        );
    }

    function registerDoctor(
        address _doctor,
        string memory _name
    ) external onlyAdmin {

        require(
            !users[_doctor].registered,
            "User already registered"
        );

        users[_doctor] = User(
            _doctor,
            _name,
            Role.Doctor,
            true
        );

        emit UserRegistered(
            _doctor,
            Role.Doctor
        );
    }

    function registerHospital(
        address _hospital,
        string memory _name
    ) external onlyAdmin {

        require(
            !users[_hospital].registered,
            "User already registered"
        );

        users[_hospital] = User(
            _hospital,
            _name,
            Role.Hospital,
            true
        );

        emit UserRegistered(
            _hospital,
            Role.Hospital
        );
    }

    // ==============================
    // CREATE MEDICAL RECORD
    // ==============================

    function createMedicalRecord(
        address _patient,
        string memory _documentType,
        string memory _metadata,
        string memory _documentHash
    )
        external
        onlyRegistered
        returns (uint256)
    {
        require(
            users[_patient].registered,
            "Patient is not registered"
        );

        require(
            users[_patient].role == Role.Patient,
            "Address is not a patient"
        );

        require(
            bytes(_documentHash).length > 0,
            "Hash required"
        );

        uint256 recordId = nextRecordId;

        records[recordId] = MedicalRecord({
            recordId: recordId,
            patient: _patient,
            uploadedBy: msg.sender,
            documentType: _documentType,
            metadata: _metadata,
            documentHash: _documentHash,
            createdAt: block.timestamp,
            active: true
        });

        patientRecords[_patient].push(recordId);

        nextRecordId++;

        emit RecordCreated(
            recordId,
            _patient,
            msg.sender,
            _documentType,
            _documentHash
        );

        return recordId;
    }

    // ==============================
    // REQUEST ACCESS
    // ==============================

    function requestAccess(
        uint256 _recordId
    )
        external
        onlyRegistered
    {
        require(
            records[_recordId].active,
            "Record does not exist"
        );

        require(
            records[_recordId].patient != msg.sender,
            "Patient already owns access"
        );

        emit AccessRequested(
            _recordId,
            msg.sender
        );
    }

    // ==============================
    // GRANT ACCESS
    // ==============================

    function grantAccess(
        uint256 _recordId,
        address _user
    )
        external
        onlyPatient
    {
        require(
            records[_recordId].patient == msg.sender,
            "Not record owner"
        );

        require(
            users[_user].registered,
            "User is not registered"
        );

        require(
            users[_user].role == Role.Doctor ||
            users[_user].role == Role.Hospital,
            "Invalid healthcare provider"
        );

        permissions[_recordId][_user] = AccessPermission({
            granted: true,
            grantedAt: block.timestamp,
            revokedAt: 0
        });

        emit AccessGranted(
            _recordId,
            msg.sender,
            _user
        );
    }

    // ==============================
    // REVOKE ACCESS
    // ==============================

    function revokeAccess(
        uint256 _recordId,
        address _user
    )
        external
        onlyPatient
    {
        require(
            records[_recordId].patient == msg.sender,
            "Not record owner"
        );

        permissions[_recordId][_user].granted = false;
        permissions[_recordId][_user].revokedAt =
            block.timestamp;

        emit AccessRevoked(
            _recordId,
            msg.sender,
            _user
        );
    }

    // ==============================
    // ACCESS RECORD
    // ==============================

    function accessRecord(
        uint256 _recordId
    )
        external
        onlyRegistered
        returns (
            string memory documentType,
            string memory metadata,
            string memory documentHash
        )
    {
        MedicalRecord memory record =
            records[_recordId];

        require(
            record.active,
            "Record is not active"
        );

        bool isPatient =
            record.patient == msg.sender;

        bool hasPermission =
            permissions[_recordId][msg.sender].granted;

        bool isUploader =
            record.uploadedBy == msg.sender;

        require(
            isPatient ||
            hasPermission ||
            isUploader,
            "Access denied"
        );

        emit RecordAccessed(
            _recordId,
            msg.sender,
            block.timestamp
        );

        return (
            record.documentType,
            record.metadata,
            record.documentHash
        );
    }

    // ==============================
    // HASH VERIFICATION
    // ==============================

    function verifyHash(
        uint256 _recordId,
        string memory _providedHash
    )
        external
        onlyRegistered
        returns (bool)
    {
        MedicalRecord memory record =
            records[_recordId];

        require(
            record.active,
            "Record does not exist"
        );

        bool isPatient =
            record.patient == msg.sender;

        bool hasPermission =
            permissions[_recordId][msg.sender].granted;

        require(
            isPatient || hasPermission,
            "Access denied"
        );

        bool valid =
            keccak256(bytes(record.documentHash)) ==
            keccak256(bytes(_providedHash));

        emit HashVerified(
            _recordId,
            msg.sender,
            valid
        );

        return valid;
    }

    // ==============================
    // GET PATIENT RECORDS
    // ==============================

    function getPatientRecords(
        address _patient
    )
        external
        view
        returns (uint256[] memory)
    {
        require(
            msg.sender == _patient,
            "Only patient can view records"
        );

        return patientRecords[_patient];
    }

    // ==============================
    // CHECK ACCESS
    // ==============================

    function hasAccess(
        uint256 _recordId,
        address _user
    )
        external
        view
        returns (bool)
    {
        return permissions[_recordId][_user].granted;
    }

    // ==============================
    // GET RECORD
    // ==============================

    function getRecord(
        uint256 _recordId
    )
        external
        view
        returns (
            uint256,
            address,
            address,
            string memory,
            string memory,
            string memory,
            uint256,
            bool
        )
    {
        MedicalRecord memory record =
            records[_recordId];

        return (
            record.recordId,
            record.patient,
            record.uploadedBy,
            record.documentType,
            record.metadata,
            record.documentHash,
            record.createdAt,
            record.active
        );
    }
}