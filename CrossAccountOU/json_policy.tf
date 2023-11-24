{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:organizations::<Organization-ID>:<Root-User>"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
