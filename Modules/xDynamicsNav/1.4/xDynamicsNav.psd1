@{
    RootModule           = 'xDynamicsNav.psm1'

    # Die Versionsnummer dieses Moduls
    ModuleVersion        = '1.4'

    # ID zur eindeutigen Kennzeichnung dieses Moduls
    GUID                 = '0f770cf8-6521-4f98-8cc4-aa689d2d42be'

    # Autor dieses Moduls
    Author               = 'Luka Weis'

    # Unternehmen oder Hersteller dieses Moduls
    CompanyName          = ''

    # Urheberrechtserklärung für dieses Modul
    Copyright            = ''

    # Beschreibung der von diesem Modul bereitgestellten Funktionen
    Description          = 'Installiert ein .exe Setup'

    # Die für dieses Modul mindestens erforderliche Version des Windows PowerShell-Moduls
    PowerShellVersion    = '5.0'

    # Aus diesem Modul zu exportierende Funktionen. Um optimale Leistung zu erzielen, verwenden Sie keine Platzhalter und löschen den Eintrag nicht. Verwenden Sie ein leeres Array, wenn keine zu exportierenden Funktionen vorhanden sind.
    FunctionsToExport    = '*'

    # Aus diesem Modul zu exportierende Cmdlets. Um optimale Leistung zu erzielen, verwenden Sie keine Platzhalter und löschen den Eintrag nicht. Verwenden Sie ein leeres Array, wenn keine zu exportierenden Cmdlets vorhanden sind.
    CmdletsToExport      = '*'

    # Die aus diesem Modul zu exportierenden Variablen
    VariablesToExport    = '*'

    # Aus diesem Modul zu exportierende Aliase. Um optimale Leistung zu erzielen, verwenden Sie keine Platzhalter und löschen den Eintrag nicht. Verwenden Sie ein leeres Array, wenn keine zu exportierenden Aliase vorhanden sind.
    AliasesToExport      = '*'

    # Aus diesem Modul zu exportierende DSC-Ressourcen
    DscResourcesToExport = @('xNavSetup', 'xNavSetupOnCore', 'xNavInstance', 'xNavImportObjects', 'xNavClientDefaults', 'xBCSetup')

}

