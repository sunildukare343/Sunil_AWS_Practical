#---------------------------------------------------------------------------------------------
# Outputs for Security Groups Module
#---------------------------------------------------------------------------------------------

output "security_group_ids" {
  value = {
    for k, sg in aws_security_group.this : k => sg.id
  }
  description = "IDs of all security groups created by this module, mapped by their keys"
}
