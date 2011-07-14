#define wxUSE_GUI 0

#include <wx/wx.h>
#include <wx/file.h>
#include <wx/fileconf.h>
#include <wx/wfstream.h>
//#include <wx/taskbar.h>

#ifdef __WXMSW__
#include "Registry.h"
#include <rpc.h>
#pragma comment(lib, "rpcrt4.lib")
#endif

#define REGISTRY_FILE wxT("/etc/postgres-reg.ini")

int main()
{
	wxInitialize();

	double majorVersion = -1;
	bool flag = false;
	long cookie = 0;

#ifdef __WXMSW__
	// Add local servers.
	pgRegKey::PGREGWOWMODE wowMode = pgRegKey::PGREG_WOW_DEFAULT;
	wxString strPgArch;

	if (::wxIsPlatform64Bit())
		wowMode = pgRegKey::PGREG_WOW32;

	pgRegKey *rootKey = pgRegKey::OpenRegKey(HKEY_LOCAL_MACHINE, wxT("Software\\PostgreSQL\\Services"), pgRegKey::PGREG_READ, wowMode);

	if (rootKey == NULL && ::wxIsPlatform64Bit())
	{
		wowMode = pgRegKey::PGREG_WOW64;
		rootKey = pgRegKey::OpenRegKey(HKEY_LOCAL_MACHINE, wxT("Software\\PostgreSQL\\Services"), pgRegKey::PGREG_READ, wowMode);
		strPgArch = wxT(" (x64)");
	}

	while (rootKey != NULL)
	{
		long cookie = 0;
		wxString svcName;
		pgRegKey *svcKey = NULL;

		flag = rootKey->GetFirstKey(svcKey, cookie);

		while (flag != false)
		{
			wxString guid;
			DWORD tmpPort = 0;
			// Get the version number from installation record
			svcKey->QueryValue(wxT("Product Code"), guid);

			if (!guid.IsEmpty())
			{
				wxString keyName;
				keyName.Printf(wxT("Software\\PostgreSQL\\Installations\\%s"), guid.c_str());

				pgRegKey *instKey = pgRegKey::OpenRegKey(HKEY_LOCAL_MACHINE, keyName, pgRegKey::PGREG_READ, wowMode);

				if (instKey != NULL)
				{
					double dVersion = -1;
					wxString serverVersion;
					if (instKey->HasValue(wxT("Version")))
					{
						instKey->QueryValue(wxT("Version"), serverVersion);
						serverVersion.ToDouble(&dVersion);
					}
					if (majorVersion < dVersion)
				    majorVersion = dVersion;
					
					delete instKey;
				}
			}
			delete svcKey;
            svcKey = NULL;

            // Get the next one...
            flag = rootKey->GetNextKey(svcKey, cookie);
		}
		delete rootKey;
        rootKey = NULL;

        if (strPgArch == wxEmptyString && ::wxIsPlatform64Bit())
        {
            wowMode = pgRegKey::PGREG_WOW64;
            rootKey = pgRegKey::OpenRegKey(HKEY_LOCAL_MACHINE, wxT("Software\\PostgreSQL\\Services"), pgRegKey::PGREG_READ, wowMode);
            strPgArch = wxT(" (x64)");
        }
	}
#else

	if (wxFile::Exists(REGISTRY_FILE))
	{
		wxString version;

		wxFileInputStream fst(REGISTRY_FILE);
		wxFileConfig *cnf = new wxFileConfig(fst);

		cnf->SetPath(wxT("/PostgreSQL"));

		flag = cnf->GetFirstGroup(version, cookie);

		while (flag)
		{
			// If there is no Version entry, this is probably an uninstalled server
			if (cnf->Read(version + wxT("/Version"), wxEmptyString) != wxEmptyString)
			{
				double dVersion;
				version.ToDouble(&dVersion);	

				if (majorVersion < dVersion)	
					majorVersion = dVersion;
			}
			flag = cnf->GetNextGroup(version, cookie);
		}
	}
#endif
	printf("%.1lf\n", majorVersion);

	return 0;
}

