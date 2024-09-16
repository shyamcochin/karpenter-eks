# Define the SQS Queue
resource "aws_sqs_queue" "karpenter_interruption_queue" {
  name                      = "${local.cluster_name}-interruption-queue"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
  tags                      = merge(local.default_tags)
}

# Define SQS Queue Policy
resource "aws_sqs_queue_policy" "karpenter_interruption_queue_policy" {
  queue_url = aws_sqs_queue.karpenter_interruption_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "EC2InterruptionPolicy"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "events.amazonaws.com",
            "sqs.amazonaws.com"
          ]
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption_queue.arn
      }
    ]
  })
}

# Define CloudWatch Event Rules
resource "aws_cloudwatch_event_rule" "scheduled_change_rule" {
  name = "${local.cluster_name}-scheduled-change-rule"
  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })
  tags       = merge(local.default_tags)
  depends_on = [aws_sqs_queue.karpenter_interruption_queue]
}

resource "aws_cloudwatch_event_rule" "spot_interruption_rule" {
  name = "${local.cluster_name}-spot-interruption-rule"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })
  tags       = merge(local.default_tags)
  depends_on = [aws_sqs_queue.karpenter_interruption_queue]
}

resource "aws_cloudwatch_event_rule" "rebalance_rule" {
  name = "${local.cluster_name}-rebalance-rule"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance Rebalance Recommendation"]
  })
  tags = merge(local.default_tags)
}

resource "aws_cloudwatch_event_rule" "instance_state_change_rule" {
  name = "${local.cluster_name}-instance-state-change-rule"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
  })
  tags = merge(local.default_tags)
}

# Define Event Targets
resource "aws_cloudwatch_event_target" "karpenter_interruption_queue_target" {
  for_each = {
    ScheduledChangeRule     = aws_cloudwatch_event_rule.scheduled_change_rule.name
    SpotInterruptionRule    = aws_cloudwatch_event_rule.spot_interruption_rule.name
    RebalanceRule           = aws_cloudwatch_event_rule.rebalance_rule.name
    InstanceStateChangeRule = aws_cloudwatch_event_rule.instance_state_change_rule.name
  }

  rule      = each.value
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn

  depends_on = [
    aws_cloudwatch_event_rule.instance_state_change_rule,
    aws_cloudwatch_event_rule.scheduled_change_rule,
    aws_cloudwatch_event_rule.spot_interruption_rule,
    aws_sqs_queue.karpenter_interruption_queue
  ]
}

# Define IAM Role for EventBridge
resource "aws_iam_role" "eventbridge_to_sqs_role" {
  name = "${local.cluster_name}-eventbridge-to-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_to_sqs_policy" {
  name = "${local.cluster_name}-eventbridge-to-sqs-policy"
  role = aws_iam_role.eventbridge_to_sqs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption_queue.arn
      }
    ]
  })
}
