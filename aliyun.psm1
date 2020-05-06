$AliyunApiVersions = @{ECS="2014-05-26";DNS="2015-01-09";VPC="2016-04-28"}
$AliyunApiEndpoints = @{ECS="ecs.aliyuncs.com";DNS="alidns.aliyuncs.com";VPC="vpc.aliyuncs.com"}
$aliyunsdkpath = (Split-Path $profile)+"\Modules\aliyun\aliyun-net-sdk-Core.dll"
Add-Type -Path $aliyunsdkpath
function Get-StringBase64{
param(
[parameter(ValueFromPipeline,Mandatory=$true)]$InputString)
return([convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($InputString)))
}
function New-AliyunCommonReq{
param(
[parameter(Mandatory=$true,Position=0)][String]$Action,
[parameter(Mandatory=$false)][switch]$Rest = $false,
[parameter(Mandatory=$false)][switch]$Rpc = $true,
[parameter(Mandatory=$false)][String]$RegionID,
[parameter(Mandatory=$false)][String]$Product,
[parameter(Mandatory=$false)][String]$EndPoint = $AliyunApiEndpoints["ECS"],
[parameter(Mandatory=$false)][String]$ApiVersion = $AliyunApiVersions["ECS"])
$commonreq = New-Object Aliyun.Acs.Core.CommonRequest
if($Rest){
$commonreq.UriPattern=$Action
}
if($RegionID){
$commonreq.RegionId = $RegionID
}
if($Rpc){
$commonreq.Action=$Action
}
if($Product){
$EndPoint = $AliyunApiEndpoints[$Product]
$ApiVersion = $AliyunApiVersions[$Product]
}
$commonreq.Domain = $EndPoint
$commonreq.Version=$ApiVersion
return $commonreq
}
function Get-AliyunCommonRes{
param(
[parameter(Mandatory=$true)]$Client,
[parameter(ValueFromPipeline,Mandatory=$true)]$Request)
$res = $Client.GetCommonResponse($Request)
if($res.HttpResponse.ContentType -eq "XML"){
return [xml]($res.Data)
}else{
return($res.Data|ConvertFrom-Json)
}
}
function Add-AliyunComReqQueryParam{
param(
[parameter(Mandatory=$true,Position=0)][String[]]$Name,
[parameter(Mandatory=$false,Position=1)][String[]]$Value,
[parameter(ValueFromPipeline,Mandatory=$true)]$Request)
$NewReq = $Request.PSObject.Copy()
For($i=0;$i -lt $Name.Length;$i++){
if($Value[$i].Length -gt 0){
$NewReq.AddQueryParameters($Name[$i], $Value[$i])
}
}
return $NewReq
}
function New-AliyunProfile{
param(
[parameter(Mandatory=$true,Position=0)][String]$RegionID,
[parameter(Mandatory=$true,Position=1)][String]$AccessKeyID,
[parameter(Mandatory=$true,Position=2)][String]$AccessSecret)
return [Aliyun.Acs.Core.Profile.DefaultProfile]::GetProfile($RegionID, $AccessKeyID, $AccessSecret)
}
function New-AliyunInstanceClient{

}
function New-AliyunClient{
param(
[parameter(ValueFromPipeline)]$AliyunProfile
)
return New-Object Aliyun.Acs.Core.DefaultAcsClient -ArgumentList $AliyunProfile
}
function Get-AliyunEcsRegions{
param(
[parameter(ValueFromPipeline,Mandatory=$true)]$Client)
return (New-AliyunCommonReq -Action "DescribeRegions" -Product "ECS" |
 Get-AliyunCommonRes -Client $Client)
}
function Get-AliyunEcsZones{
param(
[parameter(ValueFromPipeline,Mandatory=$true)]$RegionID,
[parameter(Mandatory=$true,Position=0)]$Client)
return (New-AliyunCommonReq -Action "DescribeZones" -Product "ECS" -RegionID $RegionID |
 Get-AliyunCommonRes -Client $Client)
}
function Get-AliyunImages{
param(
[parameter(ValueFromPipeline)]$RegionID,
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$false)][String]$PageNumber,
[parameter(Mandatory=$false)][String]$PageSize)
return (New-AliyunCommonReq -Action "DescribeImages" -Product "ECS" -RegionID $RegionID |
Add-AliyunComReqQueryParam -Name "PageSize","PageNumber" -Value $PageSize,$PageNumber|
Get-AliyunCommonRes -Client $Client)
}
function Get-AliyunAvailableResource{
param(
[parameter(ValueFromPipeline,Mandatory=$true)][String]$RegionID,
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$false,Position=1)][String]$ZoneID,
[parameter(Mandatory=$false)][switch]$Zones=$false,
[parameter(Mandatory=$false)][ValidateSet("InstanceType")]
[String]$DestinationResource="InstanceType",
[parameter(Mandatory=$false)][switch]$SystemDisk,
[parameter(Mandatory=$false)][switch]$DataDisk,
[parameter(Mandatory=$false)][switch]$Network
)
$req = New-AliyunCommonReq -Action "DescribeAvailableResource" -Product "ECS" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "ZoneID" -Value $ZoneID
$req = $req|Add-AliyunComReqQueryParam -Name "DestinationResource",
"IoOptimized" -Value $DestinationResource,"optimized"
$res = $req| Get-AliyunCommonRes -Client $Client
return $res
}
function Get-AliyunSecurityGroups{
param(
[parameter(ValueFromPipeline,Mandatory=$true)][String]$RegionID,
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$false)][String]$VpcID,
[parameter(Mandatory=$false)][String]$PageNumber,
[parameter(Mandatory=$false)][String]$PageSize
)
$req = New-AliyunCommonReq -Action "DescribeSecurityGroups" -Product "ECS" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "VpcId",
"PageNumber","PageSize" -Value $VpcID,$PageNumber,$PageSize
return $req | Get-AliyunCommonRes -Client $Client
}
function Get-AliyunVSwitchs{
param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$true,Position=1)][String]$RegionID,
[parameter(Mandatory=$false)][String]$VpcID,
[parameter(Mandatory=$false)][String]$ZoneID,
[parameter(Mandatory=$false)][String]$VSwitchID,
[parameter(Mandatory=$false)][String]$PageNumber,
[parameter(Mandatory=$false)][String]$PageSize
)
$req = New-AliyunCommonReq -Action "DescribeVSwitches" -Product "VPC" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "VpcId",
"ZoneId","VSwitchId","PageNumber","PageSize" -Value $VpcID,$ZoneID,$VSwitchID,$PageNumber,$PageSize
return $req|Get-AliyunCommonRes -Client $Client
}
function New-AliyunVSwitchs{
param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$true,Position=1)][String]$ZoneID,
[parameter(Mandatory=$true,Position=2)][String]$CidrBlock,
[parameter(Mandatory=$true,Position=3)][String]$VpcID,
[parameter(Mandatory=$true,Position=4)][String]$VSwitchName,
[parameter(Mandatory=$false)][String]$Description
)
$req = New-AliyunCommonReq -Action "CreateVSwitch" -Product "VPC" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "ZoneId",
"CidrBlock","VpcId","VSwitchName","Description" -Value $ZoneID,$CidrBlock,$VpcID,$VSwitchName,$Description
return $req|Get-AliyunCommonRes -Client $Client
}
function Remove-AliyunVSwitchs{param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(ValueFromPipeline,Mandatory=$true)][String]$VSwitchID)
$req = New-AliyunCommonReq -Action "DeleteVSwitch" -Product "VPC"
$req = $req|Add-AliyunComReqQueryParam -Name "VSwitchId" -Value $VSwitchID
return $req|Get-AliyunCommonRes -Client $Client
}
function Get-AliyunEipAddr{param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$true,Position=1)][String]$RegionID,
[parameter(Mandatory=$false)][String]$PageNumber,
[parameter(Mandatory=$false)][String]$PageSize
)
$req = New-AliyunCommonReq -Action "DescribeEipAddresses" -Product "VPC" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "PageNumber","PageSize" -Value $PageNumber,$PageSize
return $req|Get-AliyunCommonRes -Client $Client
}
function New-AliyunEipAddr{param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$true,Position=1)][String]$RegionID,
[parameter(Mandatory=$false)][String]$Bandwidth,
[parameter(Mandatory=$false)][ValidateSet("PayByTraffic","PayByBandwidth")]
[String]$InternetChargeType="PayByTraffic",
[parameter(Mandatory=$false)][switch]$PayByTraffic
)
$req = New-AliyunCommonReq -Action "AllocateEipAddress" -Product "VPC" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "InternetChargeType",
"Bandwidth" -Value $InternetChargeType,$Bandwidth
return $req|Get-AliyunCommonRes -Client $Client
}
function Remove-AliyunEipAddr{param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$true,Position=1)][String]$RegionID,
[parameter(ValueFromPipeline,Mandatory=$true)][String]$EipID)
$req = New-AliyunCommonReq -Action "ReleaseEipAddress" -Product "VPC" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "AllocationId" -Value $EipID
return $req|Get-AliyunCommonRes -Client $Client

}
function Set-AliyunInstanceEip{param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$true,Position=1)][String]$RegionID,
[parameter(Mandatory=$true,Position=2)][String]$EipID,
[parameter(Mandatory=$true,Position=3)][String]$InstanceID,
[parameter(Mandatory=$true,Position=4)]
[ValidateSet("AssociateEipAddress","UnassociateEipAddress")][String]$Action
)
$req = New-AliyunCommonReq -Action $Action -Product "VPC" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "AllocationId",
"InstanceId" -Value $EipID,$InstanceID
return $req|Get-AliyunCommonRes -Client $Client
}
function Get-AliyunEcsInstances{param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$true,Position=1)][String]$RegionID,
[parameter(Mandatory=$false)][String]$PageNumber,
[parameter(Mandatory=$false)][String]$PageSize
)
$req = New-AliyunCommonReq -Action "DescribeInstances" -Product "ECS" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "PageNumber","PageSize" -Value $PageNumber,$PageSize
return $req|Get-AliyunCommonRes -Client $Client
}
function New-AliyunEcsInstance{
param(
[parameter(ValueFromPipeline)][String]$UserData,
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$true,Position=1)][String]$RegionID,
[parameter(Mandatory=$true,Position=2)][String]$InstanceType,
[parameter(Mandatory=$true,Position=3)][String]$ImageID,
[parameter(Mandatory=$true,Position=4)][String]$SecurityGroupId,
[parameter(Mandatory=$true,Position=5)][String]$VSwitchId,
[parameter(Mandatory=$true,Position=6)][String]$InstanceName,
[parameter(Mandatory=$true,Position=7)][String]$HostName,
[parameter(Mandatory=$true,Position=8)][String]$Password,
[parameter(Mandatory=$false)][String]$Description,
[parameter(Mandatory=$false)][switch]$PasswordInherit,
[parameter(Mandatory=$false)][switch]$IoOptimized,
[parameter(Mandatory=$false)][String]$SystemDiskCategory,
[parameter(Mandatory=$false)][String]$SystemDiskSize,
[parameter(Mandatory=$false)][String]$SystemDiskDiskName,
[parameter(Mandatory=$false)][String]$SystemDiskDescription,
[parameter(Mandatory=$false)][String]$PrivateIpAddress,
[parameter(Mandatory=$false)][String]$ZoneID)
$req = New-AliyunCommonReq -Action "CreateInstance" -Product "ECS" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "InstanceType",
"ImageId","SecurityGroupId","VSwitchId","InstanceName",
"HostName","Password","Description","PrivateIpAddress",
"SystemDiskSize","UserData" -Value $InstanceType,
$ImageID,$SecurityGroupId,$VSwitchId,$InstanceName,$HostName,
$Password,$Description,$PrivateIpAddress,$SystemDiskSize,$UserData
return $req|Get-AliyunCommonRes -Client $Client
}
function Start-AliyunEcsInstance{param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(ValueFromPipeline,Mandatory=$true)][String]$InstanceID)
$req = New-AliyunCommonReq -Action "StartInstance" -Product "ECS" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "InstanceId" -Value $InstanceID
return $req|Get-AliyunCommonRes -Client $Client
}
function Stop-AliyunEcsInstance{param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(ValueFromPipeline,Mandatory=$true)][String]$InstanceID,
[parameter(Mandatory=$false)][switch]$Force)
$req = New-AliyunCommonReq -Action "StopInstance" -Product "ECS" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "InstanceId" -Value $InstanceID
if($Force){
$req = $req|Add-AliyunComReqQueryParam -Name "ForceStop" -Value "true"
}
return $req|Get-AliyunCommonRes -Client $Client
}
function Remove-AliyunEcsInstance{param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(ValueFromPipeline,Mandatory=$true)][String]$InstanceID,
[parameter(Mandatory=$false)][switch]$Force)
$req = New-AliyunCommonReq -Action "DeleteInstance" -Product "ECS" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "InstanceId" -Value $InstanceID
if($Force){
$req = $req|Add-AliyunComReqQueryParam -Name "Force" -Value "true"
}
return $req|Get-AliyunCommonRes -Client $Client
}
function Restart-AliyunEcsInstance{param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(ValueFromPipeline,Mandatory=$true)][String]$InstanceID,
[parameter(Mandatory=$false)][switch]$Force)
$req = New-AliyunCommonReq -Action "RebootInstance" -Product "ECS" -RegionID $RegionID
$req = $req|Add-AliyunComReqQueryParam -Name "InstanceId" -Value $InstanceID
if($Force){
$req = $req|Add-AliyunComReqQueryParam -Name "ForceStop" -Value "true"
}
return $req|Get-AliyunCommonRes -Client $Client
}
function Get-AliyunDomainRecords{
param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$true,Position=1)][String]$DomainName,
[parameter(Mandatory=$false)][String]$PageNumber,
[parameter(Mandatory=$false)][String]$PageSize,
[parameter(Mandatory=$false)][String]$Record,
[parameter(Mandatory=$false)][String]$Type,
[parameter(Mandatory=$false)][String]$Value
)
$req = New-AliyunCommonReq -Action "DescribeDomainRecords" -Product "DNS"
$req=$req|Add-AliyunComReqQueryParam -Name "DomainName",
"PageNumber","PageSize","RRKeyWord","TypeKeyWord","ValueKeyWord" -Value $DomainName,
$PageNumber,$PageSize,$Record,$Type,$Value
return $req|Get-AliyunCommonRes -Client $Client
}
function New-AliyunDomainRecord{
param(
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$true,Position=1)][String]$DomainName,
[parameter(Mandatory=$true,Position=2)][String]$Record,
[parameter(Mandatory=$true,Position=3)][String]$Type,
[parameter(Mandatory=$true,Position=4)][String]$Value,
[parameter(Mandatory=$false)][String]$TTL="600",
[parameter(Mandatory=$false)][String]$Line="default"
)
$req = New-AliyunCommonReq -Action "AddDomainRecord" -Product "DNS"
$req = $req|Add-AliyunComReqQueryParam -Name "DomainName",
"RR","Type","Value","TTL","Line" -Value $DomainName,$Record,$Type,$Value,$TTL,$Line
return $req|Get-AliyunCommonRes -Client $Client
}
function Set-AliyunDomainRecord{
param(
[parameter(ValueFromPipeline,Mandatory=$true)][String]$RecordID,
[parameter(Mandatory=$true,Position=0)]$Client,
[parameter(Mandatory=$true,Position=1)][String]$Record,
[parameter(Mandatory=$true,Position=2)][String]$Type,
[parameter(Mandatory=$true,Position=3)][String]$Value,
[parameter(Mandatory=$false)][String]$TTL="600",
[parameter(Mandatory=$false)][String]$Line="default"
)
$req = New-AliyunCommonReq -Action "UpdateDomainRecord" -Product "DNS"
$req = $req|Add-AliyunComReqQueryParam -Name "RecordId",
"RR","Type","Value","TTL","Line" -Value $RecordID,$Record,$Type,$Value,$TTL,$Line
return $req|Get-AliyunCommonRes -Client $Client
}
function Remove-AliyunDomainRecord{
param(
[parameter(ValueFromPipeline,Mandatory=$true)][String]$RecordID,
[parameter(Mandatory=$true,Position=0)]$Client
)
$req = New-AliyunCommonReq -Action "DeleteDomainRecord" -Product "DNS"
$req = $req|Add-AliyunComReqQueryParam -Name "RecordId" -Value $RecordID
return $req|Get-AliyunCommonRes -Client $Client
}