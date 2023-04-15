package dynamodbTable

import (
	"context"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

// declare constant variables
// internal constant used for secondary key that stores terraform state
const terraformStateKey = "TerraformState"

// create Dynamodb table struct
type DynamodbTable struct {
	// the Dynamodb client used for requests to the database
	Client *dynamodb.Client
	// the name of the Dynamodb table
	Name string
	// the primary key of the table
	HashKey string
}

// creates a new Dynamodb table struct
func New(name string, hashKey string, region string) *DynamodbTable {
	// sets the region option and loads credentials from environment
	cfg, err := config.LoadDefaultConfig(context.TODO(), func(o *config.LoadOptions) error {
		o.Region = region
		return nil
	})
	if err != nil {
		panic(err)
	}

	// returns the new Dynamodb table struct
	return &DynamodbTable{
		Client:  dynamodb.NewFromConfig(cfg),
		Name:    name,
		HashKey: hashKey,
	}
}

// returns the value stored at the key path
func (t DynamodbTable) GetItem(key string) (string, error) {
	// request the item from Dynamodb
	out, err := t.Client.GetItem(context.TODO(), &dynamodb.GetItemInput{
		TableName: aws.String(t.Name),
		Key: map[string]types.AttributeValue{
			t.HashKey: &types.AttributeValueMemberS{Value: key},
		},
	})
	if err != nil {
		return "", err
	}

	// if there is no item at that key return empty string
	if out.Item == nil {
		return "", nil
	}

	// return the terraform state file as a string
	return out.Item[terraformStateKey].(*types.AttributeValueMemberS).Value, nil
}

//
func (t DynamodbTable) UpdateItem(key string, tfState string) error {
	// use constant expression key and update expression prevent typos in key naming
	const expressionKey = ":" + terraformStateKey
	const updateExpression = "set " + terraformStateKey + " = " + expressionKey

	// update terraform state in Dynamodb
	_, err := t.Client.UpdateItem(context.TODO(), &dynamodb.UpdateItemInput{
		TableName: aws.String(t.Name),
		Key: map[string]types.AttributeValue{
			t.HashKey: &types.AttributeValueMemberS{Value: key},
		},
		UpdateExpression: aws.String(updateExpression),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			expressionKey: &types.AttributeValueMemberS{Value: tfState},
		},
	})
	if err != nil {
		return err
	}

	return nil
}
