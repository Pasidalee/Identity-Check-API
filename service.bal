import ballerina/http;
import ballerina/log;
import ballerina/sql;
import ballerinax/postgresql;

configurable string host = ?;
configurable string username = ?;
configurable string password = ?;
configurable string database = ?;
configurable int port = ?;

const APPROVED = "approved";
const DECLINED = "declined";
const NO_ROWS_ERROR_MSG = "Query did not retrieve any rows.";
const USER_NOT_FOUND = "User not found";

isolated service / on new http:Listener(9091) {
    private final postgresql:Client dbClient;

    public isolated function init() returns error? {
        // Initialize the database
        self.dbClient = check new (host, username, password, database, port);
    }

    isolated resource function get identitycheck(string userId) returns error? {
        log:printInfo("Identity check initiated.", userId = userId);
        string|error user = getUser(userId, self.dbClient);
        if user == userId {
            _ = check updateValidation(userId, self.dbClient);
        } else if user is error && user.message() == NO_ROWS_ERROR_MSG {
            log:printInfo("User not found in the database.", userId = userId);
        } else if user is error {
            return user;
        }
    }

}

isolated function getUser(string userId, postgresql:Client dbClient) returns string|error {
    sql:ParameterizedQuery query = `SELECT user_id FROM user_details WHERE user_id = ${userId}`;
    return dbClient->queryRow(query);
}

isolated function updateValidation(string userId, postgresql:Client dbClient) returns error? {
    sql:ParameterizedQuery query = `UPDATE certificate_requests SET user_id_check = true WHERE user_id = ${userId} AND 
            status != ${APPROVED} AND status != ${DECLINED}`;
    _ = check dbClient->execute(query);
}
