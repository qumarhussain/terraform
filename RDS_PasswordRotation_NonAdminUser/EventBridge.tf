resource "aws_cloudwatch_event_rule" "example" {
  name        = "example-event-rule"
  description = "Example Event Rule"
  
  event_pattern = jsonencode({
    source = ["your-event-source"],  # Set your event source name or use "*" for all sources
    detail = {
      dbHost             : ["$.detail.dbHost"],
      dbPort             : ["$.detail.dbPort"],
      dbName             : ["$.detail.dbName"],
      dbUsername         : ["$.detail.dbUsername"],
      masterUserSecretName: ["$.detail.masterUserSecretName"],
      nonMasterUserSecretName: ["$.detail.nonMasterUserSecretName"]
    }
  })

  event_bus_name = aws_cloudwatch_event_bus.example.name
}
