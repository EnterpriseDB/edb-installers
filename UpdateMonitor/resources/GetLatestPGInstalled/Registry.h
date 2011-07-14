/////////////////////////////////////////////////////////////////////////////
// Name:        Registry.h
// Purpose:     Read 32 bit and 64 bit windows registry
// Author:      Ashesh Vashi
// Created:     2010-05-25
// RCS-ID:      $Id: Registry.h,v 1.1 2010/06/02 10:42:12 sachin Exp $
// Copyright:   (c) EnterpriseDB
// Licence:     BSD Licence
/////////////////////////////////////////////////////////////////////////////
#ifndef __PGREG_WINREGISTRY_H__
#define __PGREG_WINREGISTRY_H__

#ifdef __WXMSW__

#include <windows.h>

class pgRegKey
{

public:
    enum PGREGWOWMODE
    {
        /*
         * Read/Write 32 bit registry for 32 bit applications,
         * Read/Write 64 bit registry for 64 bit applications
         */
        PGREG_WOW_DEFAULT,
        /* Read/Write 32 bit registry */
        PGREG_WOW32,
        /* Read/Write 64 bit registry on 64 bit windows */
        PGREG_WOW64
    };

    enum PGREGACCESSMODE
    {
        /* READ ONLY */
        PGREG_READ,
        /* READ & Write */
        PGREG_WRITE
    };

public:
    static pgRegKey* OpenRegKey(HKEY root, const wxString& subkey, PGREGACCESSMODE accessmode = PGREG_READ, PGREGWOWMODE wowMode = PGREG_WOW_DEFAULT);
    static pgRegKey* CreateRegKey(HKEY root, const wxString& subkey, PGREGWOWMODE wowMode = PGREG_WOW_DEFAULT);

    ~pgRegKey();

    static bool KeyExists(HKEY root, const wxString& subKey, PGREGWOWMODE wowMode = PGREG_WOW_DEFAULT);

    bool     GetKeyInfo(size_t *pnSubKeys, size_t *pnMaxKeyLen, size_t *pnValues, size_t *pnMaxValueLen) const;
    DWORD    GetValueType(const wxString& key) const;
    wxString GetKeyName() const;


    bool QueryValue(const wxString& strVal, LPDWORD pVal) const;
    bool QueryValue(const wxString& strVal, wxString& pVal) const;
    bool QueryValue(const wxString& strVal, LPBYTE&  pVal, DWORD& len) const;
    bool SetValue(const wxString& strVal, DWORD val);
    bool SetValue(const wxString& strVal, const wxString& val);

    bool GetFirstValue(wxString& strVal, long &lindex) const;
    bool GetNextValue(wxString& strVal, long &lindex) const;
    bool HasValue(const wxString& strVal);

    bool GetFirstKey(pgRegKey*& pkey, long &lindex) const;
    bool GetNextKey(pgRegKey*& pkey, long &lindex) const;
    bool HasKey(const wxString& strKey) const;

    wxString ToString() const;

private:
    pgRegKey(HKEY root, const wxString& subkey, PGREGWOWMODE wowMode, PGREGACCESSMODE accessMode);
    pgRegKey(const pgRegKey& keyParent, const wxString& strKey);

    void Init(HKEY root, const wxString& subkey, PGREGWOWMODE wowMode, PGREGACCESSMODE accessMode);
    void Close();

    HKEY            m_hRoot;
    HKEY            m_hKey;
    wxString        m_strName;
    DWORD           m_wowMode;
    PGREGACCESSMODE m_accessMode;

};

#endif // __WXMSW__

#endif // __PGREG_WINREGISTRY_H__

