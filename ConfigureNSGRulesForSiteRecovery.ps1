
#User Inputs

$NSGName = Read-Host 'Specify the name of the NSG'
$NSGRG = Read-Host 'Specify the name of the NSG resource group'
$SubscriptionId = Read-Host 'Specify the susbcription ID'

#variables

$Locations = @("East Asia", "Southeast Asia", "Central India","South India","North Central US","North Europe","West Europe","East US","West US","South Central US","Central US","East US 2","Japan East","Japan West","Brazil South", "Australia East", "Australia Southeast", "Canada Central", "Canada East" ,"West Central US", "West US 2", "UK West", "UK South", "UK South 2", "UK North", "Korea Central", "Korea South")
$PublicIPlocations = @("asiaeast", "asiasoutheast", "indiacentral", "indiasouth", "usnorth", "europenorth", "europewest", "useast", "uswest", "ussouth", "uscentral", "useast2", "japaneast", "japanwest", "brazilsouth", "australiaeast", "australiasoutheast", "canadacentral", "canadaeast", "uswestcentral", "uswest2", "ukwest", "uksouth", "uksouth2", "uknorth", "koreacentral", "koreasouth")


$SourceLocation = $Locations| Out-GridView -OutputMode Single -Title "Select the source location where your virtual machines are running"
$TargetLocation = $Locations| Out-GridView -OutputMode Single -Title "Select the target location where your virtual machines will be replicated to"

$SourceLocationFormatted = $PublicIPlocations[$Locations.IndexOf($SourceLocation)]  


# Sign-in with Azure account credentials

Login-AzureRmAccount

# Select Azure Subscription

Select-AzureRmSubscription -SubscriptionId $SubscriptionId

$nsg = Get-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $NSGRG 

#Step 1 : Configure NSG rules for cache storage account access by adding Storage tag

$ruleName = "Allow-Storage-account-access"       
$rulePriority = 2500
$storageRegion = $SourceLocation -replace '\s','' 
$storageRegion = "Storage."+$storageRegion

$execute = $nsg | Add-AzureRmNetworkSecurityRuleConfig -Name $ruleName -Description "Allow outbound to Storage accounts" -Access Allow -Protocol TCP -Direction Outbound -Priority $rulePriority -SourceAddressPrefix VirtualNetwork -SourcePortRange * -DestinationAddressPrefix $storageRegion -DestinationPortRange "443" | Set-AzureRmNetworkSecurityGroup




#Step 2 - Configure NSG rule for Office 365 Authentication access (login.microsoftonline.com)

        # Download the current Office 365 IP list

        $O365IPUri = "https://go.microsoft.com/fwlink/?LinkId=533185"

        $O365IPXML = Invoke-WebRequest -Uri $O365IPUri

        [xml]$O365IPXMLContent  = [xml]($O365IPXML.Content)


        $addresslist = ( $O365IPXMLContent.products.product | where-object Name -In "Identity" ).addresslist
        $IPV4addresslist = ($addresslist | where-object Type -In "IPv4").address
        $IPV4addresslist = [string[]]$IPV4addresslist


        # Build NSG rules
        $ruleName = "Allow-login-microsoftonline"  
        $rulePriority++

        $execute = $nsg | Add-AzureRmNetworkSecurityRuleConfig -Name  $ruleName -Description "Allow outbound to login.microsoftonline.com" -Access Allow -Protocol TCP -Direction Outbound -Priority $rulePriority -SourceAddressPrefix VirtualNetwork -SourcePortRange * -DestinationAddressPrefix $IPV4addresslist -DestinationPortRange "443" | Set-AzureRmNetworkSecurityGroup 

       

#Step 3 - Configure NSG rules for Site Recovery service endpoint access

        # Download the Site Recovery IP list

        $SRIPUri = "https://aka.ms/site-recovery-public-ips"

        $SRIPPage = Invoke-WebRequest -Uri $SRIPUri 


        [xml]$SiteRecoveryIPXML  = [xml][System.Text.Encoding]::UTF8.GetString($SRIPPage.Content)


        $SiteRecoveryIPs = ( $SiteRecoveryIPXML.SiteRecoveryIPAddresses.region | where-object Name -In $TargetLocation )

        $SiteRecoveryIPList = @($SiteRecoveryIPs.ServiceIP1, $SiteRecoveryIPs.MonitoringIP1)
        $SiteRecoveryIPList = [string[]]$SiteRecoveryIPList


        $rulePriority++
        $rulename = "Allow-ASR-service-access"
    
        $execute = $nsg | Add-AzureRmNetworkSecurityRuleConfig -Name $ruleName -Description "Allow outbound to Site recovery service" -Access Allow -Protocol TCP -Direction Outbound -Priority $rulePriority -SourceAddressPrefix VirtualNetwork -SourcePortRange * -DestinationAddressPrefix $SiteRecoveryIPList -DestinationPortRange "443" | Set-AzureRmNetworkSecurityGroup 
        


# SIG # Begin signature block
# MIIkEQYJKoZIhvcNAQcCoIIkAjCCI/4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAp5E9UfzNwI9Cb
# yPB5F/qq2aMamggQOR9Axx7XyPYJ4KCCDYMwggYBMIID6aADAgECAhMzAAAAxOmJ
# +HqBUOn/AAAAAADEMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMTcwODExMjAyMDI0WhcNMTgwODExMjAyMDI0WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCIirgkwwePmoB5FfwmYPxyiCz69KOXiJZGt6PLX4kvOjMuHpF4+nypH4IBtXrL
# GrwDykbrxZn3+wQd8oUK/yJuofJnPcUnGOUoH/UElEFj7OO6FYztE5o13jhwVG87
# 7K1FCTBJwb6PMJkMy3bJ93OVFnfRi7uUxwiFIO0eqDXxccLgdABLitLckevWeP6N
# +q1giD29uR+uYpe/xYSxkK7WryvTVPs12s1xkuYe/+xxa8t/CHZ04BBRSNTxAMhI
# TKMHNeVZDf18nMjmWuOF9daaDx+OpuSEF8HWyp8dAcf9SKcTkjOXIUgy+MIkogCy
# vlPKg24pW4HvOG6A87vsEwvrAgMBAAGjggGAMIIBfDAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUy9ZihM9gOer/Z8Jc0si7q7fDE5gw
# UgYDVR0RBEswSaRHMEUxDTALBgNVBAsTBE1PUFIxNDAyBgNVBAUTKzIzMDAxMitj
# ODA0YjVlYS00OWI0LTQyMzgtODM2Mi1kODUxZmEyMjU0ZmMwHwYDVR0jBBgwFoAU
# SG5k5VAF04KqFzc3IrVtqMp1ApUwVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljQ29kU2lnUENBMjAxMV8yMDEx
# LTA3LTA4LmNybDBhBggrBgEFBQcBAQRVMFMwUQYIKwYBBQUHMAKGRWh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljQ29kU2lnUENBMjAxMV8y
# MDExLTA3LTA4LmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4ICAQAG
# Fh/bV8JQyCNPolF41+34/c291cDx+RtW7VPIaUcF1cTL7OL8mVuVXxE4KMAFRRPg
# mnmIvGar27vrAlUjtz0jeEFtrvjxAFqUmYoczAmV0JocRDCppRbHukdb9Ss0i5+P
# WDfDThyvIsoQzdiCEKk18K4iyI8kpoGL3ycc5GYdiT4u/1cDTcFug6Ay67SzL1BW
# XQaxFYzIHWO3cwzj1nomDyqWRacygz6WPldJdyOJ/rEQx4rlCBVRxStaMVs5apao
# pIhrlihv8cSu6r1FF8xiToG1VBpHjpilbcBuJ8b4Jx/I7SCpC7HxzgualOJqnWmD
# oTbXbSD+hdX/w7iXNgn+PRTBmBSpwIbM74LBq1UkQxi1SIV4htD50p0/GdkUieeN
# n2gkiGg7qceATibnCCFMY/2ckxVNM7VWYE/XSrk4jv8u3bFfpENryXjPsbtrj4Ns
# h3Kq6qX7n90a1jn8ZMltPgjlfIOxrbyjunvPllakeljLEkdi0iHv/DzEMQv3Lz5k
# pTdvYFA/t0SQT6ALi75+WPbHZ4dh256YxMiMy29H4cAulO2x9rAwbexqSajplnbI
# vQjE/jv1rnM3BrJWzxnUu/WUyocc8oBqAU+2G4Fzs9NbIj86WBjfiO5nxEmnL9wl
# iz1e0Ow0RJEdvJEMdoI+78TYLaEEAo5I+e/dAs8DojCCB3owggVioAMCAQICCmEO
# kNIAAAAAAAMwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmlj
# YXRlIEF1dGhvcml0eSAyMDExMB4XDTExMDcwODIwNTkwOVoXDTI2MDcwODIxMDkw
# OVowfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UE
# AxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAKvw+nIQHC6t2G6qghBNNLrytlghn0IbKmvpWlCq
# uAY4GgRJun/DDB7dN2vGEtgL8DjCmQawyDnVARQxQtOJDXlkh36UYCRsr55JnOlo
# XtLfm1OyCizDr9mpK656Ca/XllnKYBoF6WZ26DJSJhIv56sIUM+zRLdd2MQuA3Wr
# aPPLbfM6XKEW9Ea64DhkrG5kNXimoGMPLdNAk/jj3gcN1Vx5pUkp5w2+oBN3vpQ9
# 7/vjK1oQH01WKKJ6cuASOrdJXtjt7UORg9l7snuGG9k+sYxd6IlPhBryoS9Z5JA7
# La4zWMW3Pv4y07MDPbGyr5I4ftKdgCz1TlaRITUlwzluZH9TupwPrRkjhMv0ugOG
# jfdf8NBSv4yUh7zAIXQlXxgotswnKDglmDlKNs98sZKuHCOnqWbsYR9q4ShJnV+I
# 4iVd0yFLPlLEtVc/JAPw0XpbL9Uj43BdD1FGd7P4AOG8rAKCX9vAFbO9G9RVS+c5
# oQ/pI0m8GLhEfEXkwcNyeuBy5yTfv0aZxe/CHFfbg43sTUkwp6uO3+xbn6/83bBm
# 4sGXgXvt1u1L50kppxMopqd9Z4DmimJ4X7IvhNdXnFy/dygo8e1twyiPLI9AN0/B
# 4YVEicQJTMXUpUMvdJX3bvh4IFgsE11glZo+TzOE2rCIF96eTvSWsLxGoGyY0uDW
# iIwLAgMBAAGjggHtMIIB6TAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUSG5k
# 5VAF04KqFzc3IrVtqMp1ApUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYD
# VR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUci06AjGQQ7kU
# BU7h6qfHMdEjiTQwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybC5taWNyb3Nv
# ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAz
# XzIyLmNybDBeBggrBgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAz
# XzIyLmNydDCBnwYDVR0gBIGXMIGUMIGRBgkrBgEEAYI3LgMwgYMwPwYIKwYBBQUH
# AgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvZG9jcy9wcmltYXJ5
# Y3BzLmh0bTBABggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBwAG8AbABpAGMA
# eQBfAHMAdABhAHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAZ/KG
# pZjgVHkaLtPYdGcimwuWEeFjkplCln3SeQyQwWVfLiw++MNy0W2D/r4/6ArKO79H
# qaPzadtjvyI1pZddZYSQfYtGUFXYDJJ80hpLHPM8QotS0LD9a+M+By4pm+Y9G6XU
# tR13lDni6WTJRD14eiPzE32mkHSDjfTLJgJGKsKKELukqQUMm+1o+mgulaAqPypr
# WEljHwlpblqYluSD9MCP80Yr3vw70L01724lruWvJ+3Q3fMOr5kol5hNDj0L8giJ
# 1h/DMhji8MUtzluetEk5CsYKwsatruWy2dsViFFFWDgycScaf7H0J/jeLDogaZiy
# WYlobm+nt3TDQAUGpgEqKD6CPxNNZgvAs0314Y9/HG8VfUWnduVAKmWjw11SYobD
# HWM2l4bf2vP48hahmifhzaWX0O5dY0HjWwechz4GdwbRBrF1HxS+YWG18NzGGwS+
# 30HHDiju3mUv7Jf2oVyW2ADWoUa9WfOXpQlLSBCZgB/QACnFsZulP0V3HjXG0qKi
# n3p6IvpIlR+r+0cjgPWe+L9rt0uX4ut1eBrs6jeZeRhL/9azI2h15q/6/IvrC4Dq
# aTuv/DDtBEyO3991bWORPdGdVk5Pv4BXIqF4ETIheu9BCrE/+6jMpF3BoYibV3FW
# TkhFwELJm3ZbCoBIa/15n8G9bW1qyVJzEw16UM0xghXkMIIV4AIBATCBlTB+MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNy
# b3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExAhMzAAAAxOmJ+HqBUOn/AAAAAADE
# MA0GCWCGSAFlAwQCAQUAoIHWMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCAxojY0
# RX9CXJdF7pvamM/lpe19ASK/JgHCddfJgLZRAzBqBgorBgEEAYI3AgEMMVwwWqA8
# gDoATQBpAGMAcgBvAHMAbwBmAHQAIABBAHoAdQByAGUAIABTAGkAdABlACAAUgBl
# AGMAbwB2AGUAcgB5oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbTANBgkqhkiG
# 9w0BAQEFAASCAQBTaR2rRPJBuFhOKYG/LNFlXqIcmNb0Kz31TkbBoj+sJ3g1XxcW
# 8lmm5Ib5xW8TL358TQLc/m2Rqwz9YSfNfj4vOsHxuCzwrWuv5kMjnRHkAuGXzt5+
# p1KZuJ2hHaRUJAK2hsiDu8KV640rBg4mO/6oN3OdzlsHDXbXLB0A9ecd9F6yIXB7
# dJydZEirFYkUe9vqadYm2kSHbIbWGSBn2pxMPcO2thmDMQ2Fm1K7eN5fZw707Gqp
# EjZ9huuZgBCVO5ow1FDCWqihWRx8XDJE+/UvtuUIdMqAFP/72Ngx/f3hbskQN0gA
# GSOFYZONy3IfiMsPxmXemCiQoWmJgjM2pnheoYITRjCCE0IGCisGAQQBgjcDAwEx
# ghMyMIITLgYJKoZIhvcNAQcCoIITHzCCExsCAQMxDzANBglghkgBZQMEAgEFADCC
# ATwGCyqGSIb3DQEJEAEEoIIBKwSCAScwggEjAgEBBgorBgEEAYRZCgMBMDEwDQYJ
# YIZIAWUDBAIBBQAEIPnKBd8R0VF7EXmQozfDkaU6bBc/FXL8PRwJoEm/FbvUAgZa
# snVipvQYEzIwMTgwNDE5MTAzMDQ1LjU0MlowBwIBAYACAfSggbikgbUwgbIxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDDAKBgNVBAsTA0FPQzEn
# MCUGA1UECxMebkNpcGhlciBEU0UgRVNOOkY2RkYtMkRBNy1CQjc1MSUwIwYDVQQD
# ExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloIIOyjCCBnEwggRZoAMCAQIC
# CmEJgSoAAAAAAAIwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRp
# ZmljYXRlIEF1dGhvcml0eSAyMDEwMB4XDTEwMDcwMTIxMzY1NVoXDTI1MDcwMTIx
# NDY1NVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggEiMA0GCSqGSIb3
# DQEBAQUAA4IBDwAwggEKAoIBAQCpHQ28dxGKOiDs/BOX9fp/aZRrdFQQ1aUKAIKF
# ++18aEssX8XD5WHCdrc+Zitb8BVTJwQxH0EbGpUdzgkTjnxhMFmxMEQP8WCIhFRD
# DNdNuDgIs0Ldk6zWczBXJoKjRQ3Q6vVHgc2/JGAyWGBG8lhHhjKEHnRhZ5FfgVSx
# z5NMksHEpl3RYRNuKMYa+YaAu99h/EbBJx0kZxJyGiGKr0tkiVBisV39dx898Fd1
# rL2KQk1AUdEPnAY+Z3/1ZsADlkR+79BL/W7lmsqxqPJ6Kgox8NpOBpG2iAg16Hgc
# sOmZzTznL0S6p/TcZL2kAcEgCZN4zfy8wMlEXV4WnAEFTyJNAgMBAAGjggHmMIIB
# 4jAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQU1WM6XIoxkPNDe3xGG8UzaFqF
# bVUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1Ud
# EwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYD
# VR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwv
# cHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEB
# BE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9j
# ZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwgaAGA1UdIAEB/wSBlTCB
# kjCBjwYJKwYBBAGCNy4DMIGBMD0GCCsGAQUFBwIBFjFodHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vUEtJL2RvY3MvQ1BTL2RlZmF1bHQuaHRtMEAGCCsGAQUFBwICMDQe
# MiAdAEwAZQBnAGEAbABfAFAAbwBsAGkAYwB5AF8AUwB0AGEAdABlAG0AZQBuAHQA
# LiAdMA0GCSqGSIb3DQEBCwUAA4ICAQAH5ohRDeLG4Jg/gXEDPZ2joSFvs+umzPUx
# vs8F4qn++ldtGTCzwsVmyWrf9efweL3HqJ4l4/m87WtUVwgrUYJEEvu5U4zM9GAS
# inbMQEBBm9xcF/9c+V4XNZgkVkt070IQyK+/f8Z/8jd9Wj8c8pl5SpFSAK84Dxf1
# L3mBZdmptWvkx872ynoAb0swRCQiPM/tA6WWj1kpvLb9BOFwnzJKJ/1Vry/+tuWO
# M7tiX5rbV0Dp8c6ZZpCM/2pif93FSguRJuI57BlKcWOdeyFtw5yjojz6f32WapB4
# pm3S4Zz5Hfw42JT0xqUKloakvZ4argRCg7i1gJsiOCC1JeVk7Pf0v35jWSUPei45
# V3aicaoGig+JFrphpxHLmtgOR5qAxdDNp9DvfYPw4TtxCd9ddJgiCGHasFAeb73x
# 4QDf5zEHpJM692VHeOj4qEir995yfmFrb3epgcunCaw5u+zGy9iCtHLNHfS4hQEe
# gPsbiSpUObJb2sgNVZl6h3M7COaYLeqN4DMuEin1wC9UJyH3yKxO2ii4sanblrKn
# QqLJzxlBTeCG+SqaoxFmMNO7dDJL32N79ZmKLxvHIa9Zta7cRDyXUHHXodLFVeNp
# 3lfB0d4wwP3M5k37Db9dT+mdHhk4L7zPWAUu7w2gUDXa7wknHNWzfjUeCLraNtvT
# X4/edIhJEjCCBNkwggPBoAMCAQICEzMAAAClSBdyJ/lwvmMAAAAAAKUwDQYJKoZI
# hvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEm
# MCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMTYwOTA3
# MTc1NjUwWhcNMTgwOTA3MTc1NjUwWjCBsjELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEMMAoGA1UECxMDQU9DMScwJQYDVQQLEx5uQ2lwaGVyIERT
# RSBFU046RjZGRi0yREE3LUJCNzUxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFNlcnZpY2UwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC02pLU
# vUxe8NtXB99ZYYE6JrbTGLNpw/37zCNv0g3M0xtWFsxQTb7DEvtc1sE0s8I5ybT7
# Ifoy12FsCgpebk++Cpcv0a0C5OHQ72mBnx8yxk2EJv3ie6jSIiw88cwrOTIv/hvs
# nk9v/YvHVPOFnX6CS1ISju4PYz22N0T6Tlu7X92P/uaF1wNSEZ7BlP81+4cy9hMg
# kaeaN6HyT6QyVEvgKBTl5yGG7dbDmpk0ISYwdQeYoGXoU7fQmVqUEma721ZWNNRE
# kWGJ0LjUXzpO5YA6x/JSmzp119x2qCBTIMcZtxRVdXz7ygIiDqFLgfOw5lnFGqUL
# gcoXAj5qxQuOv8G3AgMBAAGjggEbMIIBFzAdBgNVHQ4EFgQU4hOrS/LtsWC4ePGF
# oFH+cuexL6QwHwYDVR0jBBgwFoAU1WM6XIoxkPNDe3xGG8UzaFqFbVUwVgYDVR0f
# BE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJv
# ZHVjdHMvTWljVGltU3RhUENBXzIwMTAtMDctMDEuY3JsMFoGCCsGAQUFBwEBBE4w
# TDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0
# cy9NaWNUaW1TdGFQQ0FfMjAxMC0wNy0wMS5jcnQwDAYDVR0TAQH/BAIwADATBgNV
# HSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQsFAAOCAQEANn1teSvGLi8kIMol
# 9TQVjNzyS0cH9KM+7oZ4CN57h9YGxVjp+8vzF04f6TGgxtDCZgOfrs3w7JwrWZOC
# U7qRERwKnsdiGlqj1RbLLabqwPK0/3l++w7wM+pOG65c2vRQLuhLqGcZBqvH38F9
# YQUiMGHOpZjAwAIofWkxKZkgbqQ25+KU0oRs3A0aScn14zZVbW331VsR1Dm6AN+m
# 0STLSTG8JYCCYKTrGeYhgmkvSJKyUMUPDp033x68/rhy65ND/lvGHxteoGhd3g4U
# 5CLUahVW5Oji562Pyic4YmbWbNsmEi8Jg8WucEHiOR6ELQux74lwJlIEMuk8DAOe
# bGz4bqGCA3QwggJcAgEBMIHioYG4pIG1MIGyMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMQwwCgYDVQQLEwNBT0MxJzAlBgNVBAsTHm5DaXBoZXIg
# RFNFIEVTTjpGNkZGLTJEQTctQkI3NTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgU2VydmljZaIlCgEBMAkGBSsOAwIaBQADFQCbwjXd+7ImKxoUMWVQLx1T
# lGmCb6CBwTCBvqSBuzCBuDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEMMAoGA1UECxMDQU9DMScwJQYDVQQLEx5uQ2lwaGVyIE5UUyBFU046MjY2
# NS00QzNGLUM1REUxKzApBgNVBAMTIk1pY3Jvc29mdCBUaW1lIFNvdXJjZSBNYXN0
# ZXIgQ2xvY2swDQYJKoZIhvcNAQEFBQACBQDeguCXMCIYDzIwMTgwNDE5MDkzMjA3
# WhgPMjAxODA0MjAwOTMyMDdaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAN6C4JcC
# AQAwBwIBAAICF1swBwIBAAICGWAwCgIFAN6EMhcCAQAwNgYKKwYBBAGEWQoEAjEo
# MCYwDAYKKwYBBAGEWQoDAaAKMAgCAQACAxbjYKEKMAgCAQACAwehIDANBgkqhkiG
# 9w0BAQUFAAOCAQEAGEagJy55KdZjP10GGZXtndWatRPVq7FNz8IhOMYZI4q9aOCp
# 5bB4YiIWhD6+c3N/M7FFKqF6SM9twFzq79YcUX5ZCc0CjwF6DgQmAviuAlAIqelN
# EYcNpnJlszdjV63+jGQ4k8cyy3xxxD0VZZpLL3z0jG3/nwBwQs4D2/pMf16p27os
# cWKv8IDYuEpbWc52VLyABjIzku/wZdKltWYhN8zViy+/hxPRDhcuD2DJhfZ6DEiT
# i5O9eKoH4wTv5xD9+RxWD/EoAMGNi7IgPxYKoXcZkXtnZWC22/6U+0z2Io5qGVAd
# XZ1FsvcZeP9iMU9p2x/pXFtHyDQbjh3uS+5CnzGCAvUwggLxAgEBMIGTMHwxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAApUgXcif5cL5jAAAAAAClMA0G
# CWCGSAFlAwQCAQUAoIIBMjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJ
# KoZIhvcNAQkEMSIEIPYVJAEYm1haWXmIUjoAUIyf52tvZq0gExTSscO7JJ/QMIHi
# BgsqhkiG9w0BCRACDDGB0jCBzzCBzDCBsQQUm8I13fuyJisaFDFlUC8dU5Rpgm8w
# gZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYw
# JAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAKVIF3In
# +XC+YwAAAAAApTAWBBT0mQfLlzcIznOjb9SBfkqB1uGwsDANBgkqhkiG9w0BAQsF
# AASCAQCkk/ixyRgRu275vmZlooLXBhUbP5eY2Xd/FbyBVkgNSgYqoPa0C0A0xfsl
# /cnp8LZxpAo4iEA/vKO1eWtAt8vXQkDW4iJ1DKrw6IhFye/3YE9VPsmcY3UrBztV
# AV14mTKBwn4gKBLgK9fjbD6FBZL9oympOqw1LboDMC99bPahoh6Nr4NXpFbtkEQV
# y9cqhiQukobgNGOd3f/MEAqr8d95r4QiR8LVTEAIhbL/ral4ObWXqpZlXFHK73NK
# /F0gqAQO3Qs4/cFvNaw7KDOHShHnBSg3BZItS8SvlfieHKP2ZPAFiI3nQLpzFSgy
# hXKj6/LZlS+5ZxAvqonfwQ0vyoZE
# SIG # End signature block
