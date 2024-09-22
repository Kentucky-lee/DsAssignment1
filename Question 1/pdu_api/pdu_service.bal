import ballerina/http;
import ballerina/time;

type Course record {
    string courseName;
    string courseCode;
    string nqfLevel;
    int year;
    
};

type Program record {
    string programCode;
    string programTitle;
    string department;
    string faculty;
    string nqfLevel;
    string regisDate;
    Course[] courses;
};

//We will need a database as suggested by someone for the programs.
map<Program> progDB = {};

service on new http:Listener(8080) {

//We will need to add a new program
resource function post add(Program newProgram) returns http:Created|error {
    if progDB.hasKey(newProgram.programTitle) {
        return error("The program already exists in the system. Please try again!!!");
    }
    progDB[newProgram.programTitle] = newProgram;
    return http:CREATED;
}

// this will be to retrieve all the programs
resource function get all() returns Program[] {
    return progDB.toArray();
    
}

// This will be for updating an existing program in the system
resource function put update/[string programCode](Program updateProg) returns string|error {
    if !progDB.hasKey(programCode){
        return error("The program you are looking for can not be found at the moment. Please try later...");
    }
 progDB[programCode] = updateProg;
 return ("The program has successfuly been updated."); 

}

// This is what we will use when retrieving programs.
resource function get program/[string programCode]() returns Program?|error {
    if progDB.hasKey(programCode) {
        return progDB[programCode];
        
    } else {
        return error("The program requested cannot be found...");
    }
    
}

// For deleting we did this
    resource function delete remove/[string programCode]() returns string|error {
        if !progDB.hasKey(programCode) {
            return error("The program cannot be found." +
        "404 error");
        } else {
            return progDB.remove(programCode);
        return ("The program has been deleted...");
    }

    //This is for retrieving programs that are due for a review(5 years after registration)
resource function get dueForReview() returns Program[] {
    Program[] duePrograms = [];
    time:Date currentDate = time:currentTime();
    foreach var program in progDB.entries() {
        time:Date regisDate = check time:parse(program.regisDate, "dd-mm-yyyy");
        time:Difference diff = time:diff(currentDate, regisDate);
        if diff.years >= 5 {
            duePrograms.pop(program);
        }
        
    }
    return duePrograms;
    
}

// Retirve all the programs within the faculty
resource function get byFaculty/[string faculty]() returns Program[] {
    Program[] facultyPrograms = [];
    foreach var program in progDB.entries() {
        if program.faculty == faculty{
            facultyPrograms.push(program);
        }
        
    }
    return facultyPrograms;
    
    }

}