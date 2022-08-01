# demicon-iac-bridge

In order to create infrastrucutre execute these commands

# terraform init

Provide AWS access key and secret access key in folder aws_cred file cred

# terrafrom plan (Not mandatory)

# terraform apply

Generated outpus will provide ALB arn that could be searched using the provided lambda
Example or request

{
"Records": [
{
"cf": {
"config": {
"distributionId": "EXAMPLE"
},
"request": {
"uri": "/test",
"query_string": "lb_arn",
"method": "GET",
"clientIp": "2001:cdba::3257:9652",
"headers": {
"user-agent": [
{
"key": "User-Agent",
"value": "Test Agent"
}
],
"host": [
{
"key": "Host",
"value": "d123.cf.net"
}
],
"cookie": [
{
"key": "Cookie",
"value": "SomeCookie=1; AnotherOne=A; X-Experiment-Name=B"
}
]
}
}
}
}
]
}

query_string param will search through the outputs and will retrieve the value of provided key.

In order to destroy infrastructure execute

# terraform destory
