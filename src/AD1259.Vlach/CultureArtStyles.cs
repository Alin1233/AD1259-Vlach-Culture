using System.Collections.Generic;
using TaleWorlds.Engine.GauntletUI;
using TaleWorlds.GauntletUI;

namespace AD1259Vlach
{
    /// <summary>
    /// Gives the Vlach culture artwork on AD1259's character-creation culture screen.
    /// </summary>
    /// <remarks>
    /// AD1259's GUI/Brushes/ui_CharacterCreation.xml defines four parallax brushes,
    /// "Culture.Banner.Layer.1" to ".4", with one style per culture id (style "bulgaria" uses
    /// the sprites CharacterCreation\Culture\bulgaria_1..4). The culture screen switches the
    /// brush to the style named after the selected culture, so without a "vlach" style the
    /// picture would be empty. We copy the template culture's style under the new name at
    /// runtime instead of shipping a modified copy of AD1259's brush file.
    /// </remarks>
    public static class CultureArtStyles
    {
        public static readonly string[] BrushNames =
        {
            "Culture.Banner.Layer.1",
            "Culture.Banner.Layer.2",
            "Culture.Banner.Layer.3",
            "Culture.Banner.Layer.4"
        };

        /// <summary>
        /// Copies style <paramref name="fromStyle"/> to <paramref name="toStyle"/> on every culture
        /// brush. Idempotent. Returns the number of styles added; problems are appended to
        /// <paramref name="problems"/> (nothing throws for a missing brush or style).
        /// </summary>
        public static int Apply(string fromStyle, string toStyle, List<string> problems)
        {
            BrushFactory factory = UIResourceManager.BrushFactory;
            if (factory == null)
            {
                problems.Add("UIResourceManager.BrushFactory is not initialised yet.");
                return 0;
            }

            int added = 0;
            foreach (string brushName in BrushNames)
            {
                Brush brush = factory.GetBrush(brushName);
                if (brush == null || brush.Name != brushName)
                {
                    problems.Add("Brush '" + brushName + "' not found (is AD1259 enabled?).");
                    continue;
                }
                if (HasStyle(brush, toStyle))
                {
                    continue;
                }
                Style source = HasStyle(brush, fromStyle) ? brush.GetStyle(fromStyle) : null;
                if (source == null)
                {
                    problems.Add("Brush '" + brushName + "' has no '" + fromStyle + "' style to copy.");
                    continue;
                }

                // Same construction the brush loader uses: a style holds one layer per brush layer.
                var copy = new Style(brush.Layers);
                copy.FillFrom(source);
                copy.Name = toStyle;
                copy.DefaultStyle = brush.DefaultStyle;
                brush.AddStyle(copy);
                added++;
            }
            return added;
        }

        private static bool HasStyle(Brush brush, string styleName)
        {
            foreach (Style style in brush.Styles)
            {
                if (style.Name == styleName)
                {
                    return true;
                }
            }
            return false;
        }
    }
}
