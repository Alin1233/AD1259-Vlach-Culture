using System;
using System.Collections.Generic;
using System.Reflection;

namespace AD1259Vlach
{
    /// <summary>
    /// Makes AD1259's character creation aware of an extra culture.
    /// </summary>
    /// <remarks>
    /// AD1259 (v1.4.6) does not read its playable cultures from data. It keeps them in
    /// static <c>HashSet&lt;string&gt;</c> fields of <c>AD1259.Patches.CustomCultureDefinitions</c>
    /// and its Harmony patches consult those sets during character creation:
    /// <list type="bullet">
    /// <item><c>AllCultureIds</c>: cultures offered on the culture selection screen.</item>
    /// <item><c>CulturesWithOwnEquipmentsIds</c>: cultures that have their own
    /// "..._&lt;culture&gt;" character-creation equipment rosters.</item>
    /// <item>One "base group" set (here <c>EmpireCultureIds</c>, like Bulgaria): decides which
    /// family/childhood/youth backstory options are shown.</item>
    /// </list>
    /// Adding our id to those sets is all that is needed; no Harmony patch of our own.
    /// This class deliberately uses only the base class library (no TaleWorlds types), so it
    /// can be exercised outside the game by tests/Test-Module.ps1.
    /// </remarks>
    public static class CultureRegistration
    {
        public const string Ad1259AssemblyName = "AD1259";
        public const string DefinitionsTypeName = "AD1259.Patches.CustomCultureDefinitions";

        /// <summary>Fields of CustomCultureDefinitions that the culture is added to.</summary>
        public static readonly string[] TargetFields =
        {
            "AllCultureIds",
            "CulturesWithOwnEquipmentsIds",
            "EmpireCultureIds"
        };

        /// <summary>Adds <paramref name="cultureId"/> to AD1259's culture sets. Safe to call twice.</summary>
        public static RegistrationResult Register(string cultureId)
        {
            Assembly ad1259 = FindLoadedAssembly(Ad1259AssemblyName);
            if (ad1259 == null)
            {
                return RegistrationResult.Fail("AD1259.dll is not loaded. Enable Anno Domini 1259 and load it before " + VlachIds.ModuleName + ".");
            }
            return Register(ad1259, cultureId);
        }

        /// <summary>Overload used by the tests, which load AD1259.dll themselves.</summary>
        public static RegistrationResult Register(Assembly ad1259, string cultureId)
        {
            Type definitions = ad1259.GetType(DefinitionsTypeName, false);
            if (definitions == null)
            {
                return RegistrationResult.Fail("Type " + DefinitionsTypeName + " was not found in AD1259.dll. This AD1259 version is not supported (built for v1.4.6).");
            }

            // Resolve every set first, so that a partial registration never happens.
            var sets = new List<KeyValuePair<string, HashSet<string>>>();
            foreach (string fieldName in TargetFields)
            {
                FieldInfo field = definitions.GetField(fieldName, BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
                HashSet<string> set = field == null ? null : field.GetValue(null) as HashSet<string>;
                if (set == null)
                {
                    return RegistrationResult.Fail("Field " + DefinitionsTypeName + "." + fieldName + " was not found or is not a HashSet<string>. This AD1259 version is not supported (built for v1.4.6).");
                }
                sets.Add(new KeyValuePair<string, HashSet<string>>(fieldName, set));
            }

            var added = new List<string>();
            foreach (KeyValuePair<string, HashSet<string>> entry in sets)
            {
                if (entry.Value.Add(cultureId))
                {
                    added.Add(entry.Key);
                }
            }

            string message = added.Count == 0
                ? "Culture '" + cultureId + "' was already registered with AD1259."
                : "Registered culture '" + cultureId + "' with AD1259 (" + string.Join(", ", added.ToArray()) + ").";
            return RegistrationResult.Ok(message);
        }

        private static Assembly FindLoadedAssembly(string simpleName)
        {
            foreach (Assembly assembly in AppDomain.CurrentDomain.GetAssemblies())
            {
                if (string.Equals(assembly.GetName().Name, simpleName, StringComparison.OrdinalIgnoreCase))
                {
                    return assembly;
                }
            }
            return null;
        }
    }

    /// <summary>Outcome of <see cref="CultureRegistration.Register(string)"/>.</summary>
    public sealed class RegistrationResult
    {
        private RegistrationResult(bool success, string message)
        {
            Success = success;
            Message = message;
        }

        public bool Success { get; private set; }

        public string Message { get; private set; }

        public static RegistrationResult Ok(string message) { return new RegistrationResult(true, message); }

        public static RegistrationResult Fail(string message) { return new RegistrationResult(false, message); }
    }
}
