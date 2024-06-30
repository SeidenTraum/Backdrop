<h1>Backdrop</h1>
<p>
    This is a script I made to help me manage my wallpapers more easily using Swaybg on Hyprland.<br>
    It's not perfect, nor good, and you can probably find better alternatives elsewhere, but it works for me.<br>
    I hope it will work for you too.<br>
    If you have any suggestions or feedback, please let me know.<br>
    Thank you for using my script! ❤️
</p>

<h2>Usage</h2>
<p>
    Running it raw with <code>backdrop WallpaperName</code> will run swaybg and set the wallpaper.<br>
    Wallpapers by default should be in <code>~/Pictures/Wallpapers</code>, but you can change that in <code>bd.config</code>.<br>
    Due to the way my script was made, it will format the wallpapers
    to a specific naming convention. I'm planning on making it more inclusive
    in the future, but for now, you can run <code>backdrop -ss</code>
    to sanitize it.
</p>

<h3>Some other useful commands</h3>
<p>
    <code>backdrop -a</code> will add the wallpaper to the directory.<br>
    <code>backdrop -r</code> will remove the wallpaper from the directory.<br>
    <code>backdrop -c</code> will display the current wallpaper.<br>
    <code>backdrop -l</code> will list all wallpapers.<br>
    <code>backdrop -f</code> will use the fzf menu to select a wallpaper.<br>
    <code>backdrop -w</code> will use wofi to select a wallpaper.<br>
    <code>backdrop -p</code> will preview the wallpaper using kitty icat.<br>
    <code>backdrop -rr</code> will reset the wallpaper (it just kills the process and reruns it).<br>
    <code>backdrop -dd</code> will echo the wallpaper directory (kind of useless, will remove eventually).<br>
    <code>backdrop -h</code> will display the help message.<br>
</p>

<h3>Configuration</h3>
<p>
    The configuration file is located at <code>~/.config/backdrop/bd.config</code>. You can set the following options:
</p>
<ul>
    <li><code>wallpaper_dir</code>: The directory where your wallpapers are stored.</li>
    <li><code>enable_notifications</code>: Enable or disable notifications (true/false) (not implemented yet).</li>
    <li><code>enable_fzf</code>: Enable or disable fuzzy search (true/false) (also not implemented yet).</li>
</ul>

<h3>Dependencies</h3>
<p>
    The script requires the following commands to be installed:
</p>
<ul>
    <li><code>swaybg</code></li>
</ul>
<p>
    Optional dependencies:
</p>
<ul>
    <li><code>wofi</code></li>
    <li><code>fzf</code></li>
    <li><code>kitty</code></li>
</ul>

<h3>Author</h3>
<p>
    SeidenTraum (J.P.) @ github.com/SeidenTraum
</p>