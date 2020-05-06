function Get-GitTreeVolumn{
param(
[parameter(Mandatory=$true,Position=0)][String]$Treeish
)
return ((git ls-tree -r -l $Treeish)|%{[int]($_|Select-String "(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+").matches.groups[4].value}|Measure-Object -Sum).Sum
}