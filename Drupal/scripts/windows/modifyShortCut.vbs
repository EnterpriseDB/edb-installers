
Set oWS = WScript.CreateObject("WScript.Shell")
sLinkFile = "@@ALL_USERS_PROFILE@@\Start Menu\Programs\PostgreSQL\Drupal.LNK"
Set oLink = oWS.CreateShortcut(sLinkFile)
   
oLink.TargetPath = "wscript"
oLink.Arguments = """@@APACHE_HOME@@\www\Drupal\scripts\launchDrupal.vbs"""
oLink.Save
