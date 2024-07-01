<h1>Backdrop</h1>
<p>
    Este é um script que fiz para me ajudar a gerenciar meus papéis de parede mais facilmente usando Swaybg no Hyprland.<br>
    Não é perfeito, nem bom, e você provavelmente pode encontrar alternativas melhores em qualquer outro lugar, mas funciona para mim.<br>
    Espero que funcione para você também.<br>
    Se você tiver alguma sugestão ou feedback, por favor, me avise.<br>
    Obrigado por usar meu script! ❤️
</p>

<h2>Uso</h2>
<p>
    Executar diretamente com <code>backdrop NomeDoPapelDeParede</code> vai executar o swaybg e definir o papel de parede.<br>
    Os papéis de parede, por padrão, devem estar em <code>~/Pictures/Wallpapers</code>, mas você pode alterar isso no <code>bd.config</code>.<br>
    Devido à forma como meu script foi escrito, ele formatará os papéis de parede
    para uma convenção de nomenclatura específica. Estou planejando torná-lo mais inclusivo
    no futuro, mas por enquanto, você pode executar <code>backdrop -ss</code>
    para sanitizá-lo.
</p>

<h3>Outras coisas úteis</h3>
<p>
    <code>backdrop -a</code> adicionará o papel de parede ao diretório.<br>
    <code>backdrop -r</code> removerá o papel de parede do diretório.<br>
    <code>backdrop -c</code> exibirá o papel de parede atual.<br>
    <code>backdrop -l</code> listará todos os papéis de parede.<br>
    <code>backdrop -f</code> usará o menu fzf para selecionar um papel de parede.<br>
    <code>backdrop -w</code> usará wofi para selecionar um papel de parede.<br>
    <code>backdrop -p</code> pré-visualizará o papel de parede usando kitty icat.<br>
    <code>backdrop -rr</code> redefinirá o papel de parede (apenas mata o processo e o reinicia).<br>
    <code>backdrop -dd</code> exibirá o diretório de papéis de parede (meio inútil, será removido eventualmente).<br>
    <code>backdrop -h</code> exibirá a mensagem de ajuda.<br>
</p>

<h3>Configuração</h3>
<p>
    O arquivo de configuração está localizado em <code>~/.config/backdrop/bd.config</code>. Você pode definir as seguintes opções:
</p>
<ul>
    <li><code>wallpaper_dir</code>: O diretório onde seus papéis de parede estão armazenados.</li>
    <li><code>enable_notifications</code>: Ativar ou desativar notificações (true/false).</li>
    <li><code>enable_fzf</code>: Ativar ou desativar busca fuzzy (true/false).</li>
</ul>

<h3>Dependências</h3>
<p>
    O script requer os seguintes programas instalados:
</p>
<ul>
    <li><code>swaybg</code></li>
</ul>
<p>
    Dependências opcionais:
</p>
<ul>
    <li><code>wofi</code></li>
    <li><code>fzf</code></li>
    <li><code>kitty</code></li>
</ul>

<h3>Autor</h3>
<p>
    SeidenTraum (J.P.) @ github.com/SeidenTraum
</p>