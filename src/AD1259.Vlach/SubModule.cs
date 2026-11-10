using System;
using System.Collections.Generic;
using TaleWorlds.Library;
using TaleWorlds.MountAndBlade;

namespace AD1259Vlach
{
    /// <summary>
    /// Entry point declared in SubModule.xml. All game content (culture, troops, settlements,
    /// texts) is plain module data; this class only does the two things data cannot do:
    /// register the culture with AD1259's character creation and give it culture-screen art.
    /// </summary>
    public class SubModule : MBSubModuleBase
    {
        private const string LogPrefix = "[" + VlachIds.ModuleId + "] ";

        private readonly List<string> _pendingWarnings = new List<string>();
        private bool _artApplied;

        protected override void OnSubModuleLoad()
        {
            base.OnSubModuleLoad();
            try
            {
                // AD1259 is loaded before us (DependedModules), so its assembly is available here,
                // long before character creation reads the culture sets.
                RegistrationResult result = CultureRegistration.Register(VlachIds.CultureId);
                Log(result.Message);
                if (!result.Success)
                {
                    _pendingWarnings.Add(result.Message + " The Vlach culture will not be selectable.");
                }
            }
            catch (Exception e)
            {
                Log("Culture registration failed: " + e);
                _pendingWarnings.Add("Culture registration failed: " + e.Message);
            }
        }

        protected override void OnBeforeInitialModuleScreenSetAsRoot()
        {
            base.OnBeforeInitialModuleScreenSetAsRoot();

            // Brushes are loaded by now (UI resources load before the main menu). Called every
            // time the main menu is shown, so it is guarded and the work itself is idempotent.
            if (!_artApplied)
            {
                _artApplied = true;
                try
                {
                    var problems = new List<string>();
                    int added = CultureArtStyles.Apply(VlachIds.TemplateCultureId, VlachIds.CultureId, problems);
                    Log("Added " + added + " character-creation art style(s) for '" + VlachIds.CultureId + "'.");
                    foreach (string problem in problems)
                    {
                        Log("Art: " + problem);
                    }
                    if (problems.Count > 0)
                    {
                        _pendingWarnings.Add("Character-creation art could not be fully set up (see rgl log).");
                    }
                }
                catch (Exception e)
                {
                    Log("Adding character-creation art failed: " + e);
                    _pendingWarnings.Add("Character-creation art failed: " + e.Message);
                }
            }

            // Problems are shown once, on the main menu, where the player can see them.
            foreach (string warning in _pendingWarnings)
            {
                InformationManager.DisplayMessage(new InformationMessage(VlachIds.ModuleName + ": " + warning, new Color(1f, 0.45f, 0.35f)));
            }
            _pendingWarnings.Clear();
        }

        private static void Log(string message)
        {
            Debug.Print(LogPrefix + message);
        }
    }
}
