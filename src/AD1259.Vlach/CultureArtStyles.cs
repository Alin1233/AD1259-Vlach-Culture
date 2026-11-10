using System.Collections.Generic;
using TaleWorlds.Engine.GauntletUI;
using TaleWorlds.GauntletUI;
using TaleWorlds.TwoDimension;

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
                if (!HasStyle(brush, fromStyle))
                {
                    problems.Add("Brush '" + brushName + "' has no '" + fromStyle + "' style to copy.");
                    continue;
                }
                CopyStyle(brush, fromStyle, toStyle);
                added++;
            }
            return added;
        }

        /// <summary>
        /// Adds a copy of style <paramref name="fromStyle"/> named <paramref name="toStyle"/> to
        /// <paramref name="brush"/>. The brush must have <paramref name="fromStyle"/>.
        /// </summary>
        public static Style CopyStyle(Brush brush, string fromStyle, string toStyle)
        {
            Style source = brush.GetStyle(fromStyle);

            // Same construction the brush loader uses: a style holds one layer per brush layer.
            var copy = new Style(brush.Layers);
            // DefaultStyle must be set before FillFrom: Style's property setters compare against
            // the current value, and an unset property reads through to DefaultStyle.
            copy.DefaultStyle = brush.DefaultStyle;
            copy.FillFrom(source);
            copy.Name = toStyle;
            brush.AddStyle(copy);
            return copy;
        }

        /// <summary>
        /// Sprite-name prefix of the culture artwork. The culture cards in the selection list
        /// (CharacterCreationCultureVisualBrushWidget with small visuals) look up the sprite
        /// "CharacterCreation\Culture\" + culture id by name and fall back to
        /// "CharacterCreation\Culture\blank_culture" (the placeholder) when it does not exist.
        /// </summary>
        public const string SpritePrefix = @"CharacterCreation\Culture\";

        public static readonly string[] SpriteSuffixes = { "", "_1", "_2", "_3", "_4" };

        /// <summary>
        /// Registers the template culture's sprites under the new culture's names in the game's
        /// sprite table. Returns the number of aliases added; problems go to <paramref name="problems"/>.
        /// </summary>
        public static int ApplySprites(string fromCulture, string toCulture, List<string> problems)
        {
            SpriteData data = UIResourceManager.SpriteData;
            if (data == null)
            {
                problems.Add("UIResourceManager.SpriteData is not initialised yet.");
                return 0;
            }
            return AddSpriteAliases(data, fromCulture, toCulture, problems);
        }

        /// <summary>
        /// Adds "CharacterCreation\Culture\{toCulture}{suffix}" as an alias of the
        /// "{fromCulture}{suffix}" sprite for each suffix. The Sprite object is shared, so its
        /// sprite category (texture sheet) is loaded and unloaded exactly as for the template
        /// culture. Idempotent; an existing sprite of the new name is never replaced.
        /// </summary>
        public static int AddSpriteAliases(SpriteData data, string fromCulture, string toCulture, List<string> problems)
        {
            int added = 0;
            foreach (string suffix in SpriteSuffixes)
            {
                string toName = SpritePrefix + toCulture + suffix;
                if (data.Sprites.ContainsKey(toName))
                {
                    continue;
                }
                string fromName = SpritePrefix + fromCulture + suffix;
                Sprite source;
                if (!data.Sprites.TryGetValue(fromName, out source) || source == null)
                {
                    problems.Add("Sprite '" + fromName + "' not found (is AD1259 enabled?).");
                    continue;
                }
                data.Sprites[toName] = source;
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
