package main

import (
	"fmt"
	"internal/dynamodbTable"
	"io/ioutil"
	"net/http"
)

// create a handler struct
type HttpHandler struct {
	DynamodbTable *dynamodbTable.DynamodbTable
}

// processes all http requests to GET or POST terraform state
func (h HttpHandler) ServeHTTP(res http.ResponseWriter, req *http.Request) {
	// switch on http method
	switch req.Method {

	// GET request
	case http.MethodGet:
		// check dynamodb table for terraform state
		tfState, err := h.DynamodbTable.GetItem(req.URL.Path)
		if err != nil {
			// assume server error if Dynamodb get fails
			// return internal server error code
			res.WriteHeader(500)
			fmt.Fprint(res, "Failed to get item from Dynamodb.")
			break
		}

		// return the terraform state
		fmt.Fprint(res, tfState)

	// POST request
	case http.MethodPost:
		// read bytes from request body
		bodyBytes, err := ioutil.ReadAll(req.Body)
		if err != nil {
			// assume client error if reading the body fails
			// return bad request error code
			res.WriteHeader(400)
			fmt.Fprint(res, "Couldn't read request body.")
			break
		}

		// convert bytes from body into string containing terraform state
		tfState := fmt.Sprintf("%s", bodyBytes)

		// upload terraform state to Dynamodb
		err = h.DynamodbTable.UpdateItem(req.URL.Path, tfState)
		if err != nil {
			// assume server error if Dynamodb update fails
			// return internal server error code
			res.WriteHeader(500)
			fmt.Fprint(res, "Failed to update item in Dynamodb.")
			break
		}

		// return 200 OK response
		fmt.Fprint(res, "Successfully updated terraform state.")

	// unsupported HTTP method in request
	default:
		// return bad request error code
		res.WriteHeader(400)
		fmt.Fprint(res, "Method must be GET or POST.")
	}
}

// starts the webserver
func main() {
	// create a new handler
	handler := HttpHandler{
		DynamodbTable: dynamodbTable.New("Terraform-Backend-Store", "ProjectKey", "us-east-2"),
	}

	// listen and serve
	http.ListenAndServe(":8080", handler)
}
