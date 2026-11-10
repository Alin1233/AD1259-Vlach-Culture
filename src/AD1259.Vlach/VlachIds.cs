namespace AD1259Vlach
{
    /// <summary>Identifiers shared by the DLL and the module data (see Module/ModuleData).</summary>
    public static class VlachIds
    {
        /// <summary>Folder name and Id in SubModule.xml.</summary>
        public const string ModuleId = "AD1259_Vlach";

        /// <summary>Display name used in log lines and on-screen messages.</summary>
        public const string ModuleName = "AD1259 - Vlach Culture";

        /// <summary>Culture id defined in vlach_generated_culture.xml.</summary>
        public const string CultureId = "vlach";

        /// <summary>
        /// Culture the Vlachs are modelled on. Its character-creation art is reused and the
        /// Vlachs join the same AD1259 backstory group (the Empire-style narrative).
        /// </summary>
        public const string TemplateCultureId = "bulgaria";
    }
}
