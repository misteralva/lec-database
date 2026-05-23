<?php
require_once __DIR__ . '/clases/ConexionDB.php';
require_once __DIR__ . '/clases/LecDB.php';
require_once __DIR__ . '/ImagenHelper.php';

$pdo = ConexionDB::getInstancia('readonly')->getConexion();

$splits = $pdo->query("
    SELECT DISTINCT s.id_split, s.nombre, s.año
    FROM split s JOIN fase_split fs ON s.id_split=fs.id_split
    WHERE fs.tipo='PLAYOFFS'
    ORDER BY s.año DESC, s.id_split DESC
")->fetchAll();

$idSplitSel = isset($_GET['split']) ? (int)$_GET['split'] : ($splits[0]['id_split'] ?? 0);
$splitActual = null;
foreach ($splits as $s) { if ($s['id_split']==$idSplitSel) { $splitActual=$s; break; } }

$idFase = null;
if ($idSplitSel) {
    $f=$pdo->prepare("SELECT id_fase FROM fase_split WHERE id_split=? AND tipo='PLAYOFFS' LIMIT 1");
    $f->execute([$idSplitSel]);
    $idFase=$f->fetchColumn();
}

$matchesRaw=[];
if ($idFase) {
    $stmt=$pdo->prepare("
        SELECT p.id_partido, p.mapas_eq1, p.mapas_eq2, p.tipo_serie, p.finalizado,
               e1.nombre AS eq1, e2.nombre AS eq2
        FROM partido p
        JOIN historial_equipo he1 ON p.id_historial_equipo_1=he1.id_historial_equipo
        JOIN historial_equipo he2 ON p.id_historial_equipo_2=he2.id_historial_equipo
        JOIN equipo e1 ON he1.id_equipo=e1.id_equipo
        JOIN equipo e2 ON he2.id_equipo=e2.id_equipo
        WHERE p.id_fase=?
        ORDER BY p.fecha_hora ASC, p.id_partido ASC
    ");
    $stmt->execute([$idFase]);
    $matchesRaw=$stmt->fetchAll();
}

function matchCard(?array $m, string $id=''): string {
    $idAttr = $id ? "id=\"$id\"" : '';
    if (!$m) {
        return "<div class='bk-match bk-tbd' $idAttr>
            <div class='bk-team'><span class='bk-logo-ph'></span><span class='bk-tname'>TBD</span><span class='bk-sc'></span></div>
            <div class='bk-team'><span class='bk-logo-ph'></span><span class='bk-tname'>TBD</span><span class='bk-sc'></span></div>
        </div>";
    }
    $w1=$m['finalizado']&&$m['mapas_eq1']>$m['mapas_eq2'];
    $w2=$m['finalizado']&&$m['mapas_eq2']>$m['mapas_eq1'];
    $fin=$m['finalizado'];
    $n1=htmlspecialchars($m['eq1']); $n2=htmlspecialchars($m['eq2']);
    $l1=htmlspecialchars(ImagenHelper::logoEquipo($m['eq1']));
    $l2=htmlspecialchars(ImagenHelper::logoEquipo($m['eq2']));
    $c1=$w1?'bk-win':($fin?'bk-lose':''); $c2=$w2?'bk-win':($fin?'bk-lose':'');
    $s1=$fin?$m['mapas_eq1']:''; $s2=$fin?$m['mapas_eq2']:'';
    return "<div class='bk-match' $idAttr>
        <div class='bk-team $c1'>
            <img class='bk-logo' src='$l1' alt='$n1' onerror='this.style.opacity=0'>
            <span class='bk-tname'>$n1</span>
            <span class='bk-sc'>$s1</span>
        </div>
        <div class='bk-team $c2'>
            <img class='bk-logo' src='$l2' alt='$n2' onerror='this.style.opacity=0'>
            <span class='bk-tname'>$n2</span>
            <span class='bk-sc'>$s2</span>
        </div>
    </div>";
}

function g(?array $r,int $i):?array{return $r[$i]??null;}
$n=count($matchesRaw);
$splitNombre=$splitActual?htmlspecialchars(($splitActual['nombre']==='Winter'?'LEC Versus':$splitActual['nombre']).' '.$splitActual['año']):'';

$paginaActiva='clasificacion'; $tituloPagina='Playoffs';
require_once __DIR__ . '/includes/header.php';
?>

<style>
.bk-wrap {
    overflow-x: auto;
    padding: 1.5rem 0 2rem;
}
.bk-section-title {
    font-family: var(--font-h);
    font-size: .6rem;
    font-weight: 800;
    letter-spacing: 3px;
    text-transform: uppercase;
    color: rgba(255,255,255,.25);
    padding: .4rem .8rem;
    border-left: 2px solid var(--cyan);
    margin-bottom: 1rem;
}

.bk-grid {
    display: flex;
    align-items: stretch;
    min-width: 800px;
}
.bk-col {
    display: flex;
    flex-direction: column;
    justify-content: space-around;
    min-width: 200px;
    flex: 1;
}
.bk-col-label {
    font-family: var(--font-h);
    font-size: .55rem;
    font-weight: 700;
    letter-spacing: 2px;
    text-transform: uppercase;
    color: rgba(255,255,255,.18);
    background: rgba(255,255,255,.03);
    border: 1px solid rgba(255,255,255,.06);
    border-bottom: 2px solid rgba(255,255,255,.06);
    padding: .4rem .8rem;
    margin-bottom: .5rem;
    white-space: nowrap;
}

.bk-match {
    background: #111;
    border: 1px solid rgba(255,255,255,.08);
    border-radius: 2px;
    overflow: hidden;
    position: relative;
    transition: border-color .15s;
    margin: .25rem 0;
}
.bk-match:hover { border-color: rgba(255,255,255,.2); }
.bk-tbd { opacity: .35; }
.bk-team {
    display: flex;
    align-items: center;
    gap: .6rem;
    padding: .55rem .8rem;
    border-bottom: 1px solid rgba(255,255,255,.05);
    border-left: 2px solid transparent;
}
.bk-team:last-child { border-bottom: none; }
.bk-logo {
    width: 20px; height: 20px;
    object-fit: contain; flex-shrink: 0;
}
.bk-logo-ph { width: 20px; height: 20px; flex-shrink: 0; }
.bk-tname {
    flex: 1;
    font-family: var(--font-h);
    font-size: .82rem;
    font-weight: 700;
    color: rgba(255,255,255,.4);
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.bk-sc {
    font-family: var(--font-h);
    font-size: .9rem;
    font-weight: 900;
    color: rgba(255,255,255,.2);
    min-width: 16px;
    text-align: right;
}

.bk-win { border-left-color: var(--win) !important; }
.bk-win .bk-tname { color: #fff; }
.bk-win .bk-sc    { color: var(--win); }

.bk-lose .bk-logo { opacity: .2; filter: grayscale(1); }
.bk-lose .bk-tname { color: rgba(255,255,255,.2); }
.bk-lose .bk-sc   { color: rgba(255,255,255,.15); }


.bk-conn {
    width: 40px;
    flex-shrink: 0;
    display: flex;
    flex-direction: column;
    position: relative;
}
.bk-conn-group {
    flex: 1;
    display: flex;
    flex-direction: column;
    position: relative;
}
.bk-conn-top {
    flex: 1;
    border-right: 1px solid rgba(255,255,255,.15);
    border-bottom: 1px solid rgba(255,255,255,.15);
}
.bk-conn-bot {
    flex: 1;
    border-right: 1px solid rgba(255,255,255,.15);
    border-top: 1px solid rgba(255,255,255,.15);
}
.bk-conn-mid {
    width: 100%;
    height: 1px;
    background: rgba(255,255,255,.15);
    align-self: center;
}
.bk-conn-single {
    flex: 1;
    border-top: 1px solid rgba(255,255,255,.15);
    margin-top: calc(50% + 28px);
}

.bk-final-col {
    min-width: 220px;
    display: flex;
    flex-direction: column;
    justify-content: center;
}
.bk-final-label {
    font-family: var(--font-h);
    font-size: .55rem;
    font-weight: 700;
    letter-spacing: 2px;
    text-transform: uppercase;
    color: rgba(255,255,255,.18);
    background: rgba(255,255,255,.03);
    border: 1px solid rgba(255,255,255,.06);
    border-bottom: 2px solid var(--cyan);
    padding: .4rem .8rem;
    margin-bottom: .5rem;
    white-space: nowrap;
}
.bk-final-col .bk-match {
    border-color: rgba(10,200,185,.2);
}

.bk-divider {
    height: 2rem;
    border-left: 1px dashed rgba(255,255,255,.05);
    margin: .5rem 0 1rem;
}
</style>

<main>
<div class="seccion">

    <div class="playoff-tabs">
        <a href="clasificacion.php" class="playoff-tab">Clasificación anual</a>
        <a href="playoffs.php"      class="playoff-tab playoff-tab--active">Playoffs</a>
    </div>

    <div class="seccion-cabecera" style="margin-top:1.5rem">
        <h2>Playoffs <?= $splitNombre ?></h2>
        <form method="GET" class="filtro-form">
            <label>Split:</label>
            <select name="split" onchange="this.form.submit()">
                <?php foreach ($splits as $s): ?>
                <option value="<?= $s['id_split'] ?>" <?= $s['id_split']==$idSplitSel?'selected':'' ?>>
                    <?= htmlspecialchars($s['nombre']==='Winter'?'LEC Versus':$s['nombre']) ?> <?= $s['año'] ?>
                </option>
                <?php endforeach; ?>
            </select>
        </form>
    </div>

    <div class="bk-wrap">
    <?php if ($n===0): ?>
        <p class="aviso">No hay partidos de playoffs registrados para este split.</p>

    <?php elseif ($n<=3): ?>
   
    <div class="bk-section-title">CUADRO SUPERIOR</div>
    <div class="bk-grid">
        <div class="bk-col">
            <div class="bk-col-label">CUADRO SUPERIOR: RONDA 1</div>
            <?= matchCard(g($matchesRaw,0)) ?>
            <?= matchCard(g($matchesRaw,1)) ?>
        </div>
        <div class="bk-conn">
            <div class="bk-conn-group"><div class="bk-conn-top"></div><div class="bk-conn-bot"></div></div>
        </div>
        <div class="bk-final-col">
            <div class="bk-final-label">FINAL</div>
            <?= matchCard(g($matchesRaw,2)) ?>
        </div>
    </div>

    <?php elseif ($n<=5): ?>
  
    <div class="bk-section-title">CUADRO SUPERIOR (WINNER BRACKET)</div>
    <div class="bk-grid">
        <div class="bk-col">
            <div class="bk-col-label">CUADRO SUPERIOR: RONDA 1</div>
            <?= matchCard(g($matchesRaw,0)) ?>
            <?= matchCard(g($matchesRaw,1)) ?>
        </div>
        <div class="bk-conn">
            <div class="bk-conn-group"><div class="bk-conn-top"></div><div class="bk-conn-bot"></div></div>
        </div>
        <div class="bk-col" style="justify-content:center">
            <div class="bk-col-label">CUADRO SUPERIOR: FINAL</div>
            <?= matchCard(g($matchesRaw,2)) ?>
        </div>
    </div>
    <div class="bk-section-title" style="margin-top:2rem">CUADRO INFERIOR (LOSER BRACKET)</div>
    <div class="bk-grid">
        <div class="bk-col" style="justify-content:center">
            <div class="bk-col-label">CUADRO INFERIOR: RONDA 1</div>
            <?= matchCard(g($matchesRaw,3)) ?>
        </div>
        <div class="bk-conn"><div class="bk-conn-mid" style="margin-top:48px"></div></div>
        <div class="bk-col" style="justify-content:center">
            <div class="bk-col-label">CUADRO INFERIOR: FINAL</div>
            <?= matchCard(g($matchesRaw,4)) ?>
        </div>
        <div class="bk-conn"><div class="bk-conn-mid" style="margin-top:48px"></div></div>
        <div class="bk-final-col">
            <div class="bk-final-label">FINAL</div>
            <?= matchCard(g($matchesRaw,5)??null) ?>
        </div>
    </div>

    <?php elseif ($n<=8): ?>
   
    <div class="bk-section-title">CUADRO SUPERIOR (WINNER BRACKET)</div>
    <div class="bk-grid">
        <div class="bk-col">
            <div class="bk-col-label">CUADRO SUPERIOR: RONDA 1</div>
            <?= matchCard(g($matchesRaw,0)) ?>
            <?= matchCard(g($matchesRaw,1)) ?>
        </div>
        <div class="bk-conn">
            <div class="bk-conn-group"><div class="bk-conn-top"></div><div class="bk-conn-bot"></div></div>
        </div>
        <div class="bk-col" style="justify-content:center">
            <div class="bk-col-label">CUADRO SUPERIOR: FINAL</div>
            <?= matchCard(g($matchesRaw,4)) ?>
        </div>
    </div>
    <div class="bk-section-title" style="margin-top:2rem">CUADRO INFERIOR (LOSER BRACKET)</div>
    <div class="bk-grid">
        <div class="bk-col">
            <div class="bk-col-label">CUADRO INFERIOR: RONDA 1</div>
            <?= matchCard(g($matchesRaw,2)) ?>
            <?= matchCard(g($matchesRaw,3)) ?>
        </div>
        <div class="bk-conn">
            <div class="bk-conn-group"><div class="bk-conn-top"></div><div class="bk-conn-bot"></div></div>
        </div>
        <div class="bk-col" style="justify-content:center">
            <div class="bk-col-label">CUADRO INFERIOR: SEMIFINAL</div>
            <?= matchCard(g($matchesRaw,5)) ?>
        </div>
        <div class="bk-conn"><div class="bk-conn-mid" style="margin-top:48px"></div></div>
        <div class="bk-col" style="justify-content:center">
            <div class="bk-col-label">CUADRO INFERIOR: FINAL</div>
            <?= matchCard(g($matchesRaw,6)) ?>
        </div>
        <div class="bk-conn"><div class="bk-conn-mid" style="margin-top:48px"></div></div>
        <div class="bk-final-col">
            <div class="bk-final-label">FINAL</div>
            <?= matchCard(g($matchesRaw,7)) ?>
        </div>
    </div>

    <?php else: ?>
  
    <div class="bk-section-title">CUADRO SUPERIOR (WINNER BRACKET)</div>
    <div class="bk-grid">
        <div class="bk-col">
            <div class="bk-col-label">CUADRO SUPERIOR: RONDA 1</div>
            <?= matchCard(g($matchesRaw,0)) ?>
            <?= matchCard(g($matchesRaw,1)) ?>
            <?= matchCard(g($matchesRaw,2)) ?>
            <?= matchCard(g($matchesRaw,3)) ?>
        </div>
        <div class="bk-conn">
            <div class="bk-conn-group"><div class="bk-conn-top"></div><div class="bk-conn-bot"></div></div>
            <div class="bk-conn-group"><div class="bk-conn-top"></div><div class="bk-conn-bot"></div></div>
        </div>
        <div class="bk-col" style="justify-content:space-around">
            <div class="bk-col-label">CUADRO SUPERIOR: RONDA 2</div>
            <?= matchCard(g($matchesRaw,4)) ?>
            <?= matchCard(g($matchesRaw,5)) ?>
        </div>
        <div class="bk-conn">
            <div class="bk-conn-group"><div class="bk-conn-top"></div><div class="bk-conn-bot"></div></div>
        </div>
        <div class="bk-col" style="justify-content:center">
            <div class="bk-col-label">CUADRO SUPERIOR: SEMIFINAL</div>
            <?= matchCard(g($matchesRaw,6)) ?>
        </div>
    </div>
    <div class="bk-section-title" style="margin-top:2.5rem">CUADRO INFERIOR (LOSER BRACKET)</div>
    <div class="bk-grid">
        <div class="bk-col">
            <div class="bk-col-label">CUADRO INFERIOR: RONDA 1</div>
            <?= matchCard(g($matchesRaw,7)) ?>
            <?= matchCard(g($matchesRaw,8)) ?>
        </div>
        <div class="bk-conn">
            <div class="bk-conn-group"><div class="bk-conn-top"></div><div class="bk-conn-bot"></div></div>
        </div>
        <div class="bk-col" style="justify-content:space-around">
            <div class="bk-col-label">CUADRO INFERIOR: RONDA 2</div>
            <?= matchCard(g($matchesRaw,9)) ?>
            <?= matchCard(g($matchesRaw,10)) ?>
        </div>
        <div class="bk-conn">
            <div class="bk-conn-group"><div class="bk-conn-top"></div><div class="bk-conn-bot"></div></div>
        </div>
        <div class="bk-col" style="justify-content:center">
            <div class="bk-col-label">CUADRO INFERIOR: RONDA 3</div>
            <?= matchCard(g($matchesRaw,11)) ?>
        </div>
        <div class="bk-conn"><div class="bk-conn-mid" style="margin-top:48px"></div></div>
        <div class="bk-col" style="justify-content:center">
            <div class="bk-col-label">CUADRO INFERIOR: FINAL</div>
            <?= matchCard(g($matchesRaw,12)) ?>
        </div>
        <div class="bk-conn"><div class="bk-conn-mid" style="margin-top:48px"></div></div>
        <div class="bk-final-col">
            <div class="bk-final-label">FINAL</div>
            <?= matchCard(g($matchesRaw,13)) ?>
        </div>
    </div>
    <?php endif; ?>
    </div>
</div>
</main>
<?php require_once __DIR__ . '/includes/footer.php'; ?>