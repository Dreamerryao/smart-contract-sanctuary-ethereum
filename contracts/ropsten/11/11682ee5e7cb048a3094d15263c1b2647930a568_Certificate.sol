pragma solidity ^0.4.17;

contract Certificate {

    struct WelTecStudent {
        string name;
        bytes32 id;
        string course;
    }

    struct WelTecCourse {
        string programName;
        string duration;
        bytes32 courseId;
    }

    mapping(bytes32 => WelTecStudent) public students;
    mapping(bytes32 => WelTecCourse) public courses;

    uint public studentCount;

    function Certificate() public {
    
        addStudent("maria", "weltec001", "ece");
        addStudent("saroniya", "weltec002", "soc");
        addStudent("steve", "weltec003", "hrm");
    }

    function addStudent(string _name, bytes32 _id, string _course) public {
        studentCount++;
        students[_id] = WelTecStudent(_name, _id, _course);
    }


    function updateStudent(string _name, bytes32 _id, string _course) private {
        students[_id] = WelTecStudent(_name, _id, _course);
    }

    function addCourse(string _programName, string _duration, bytes32 _courseId) private {
        courses[_courseId] = WelTecCourse(_programName, _duration, _courseId);
    }


}