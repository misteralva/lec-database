/* ================================================================
   LEC — Estadísticas · Chart.js
   ================================================================ */

const C = {
    bg:      '#010A13',
    s1:      '#050e1c',
    s2:      '#0b1628',
    s3:      '#111d30',
    border:  'rgba(255,255,255,.07)',
    text:    '#E8E6E3',
    text2:   '#6b7a8d',
    text3:   '#2e3a4a',
    gold:    '#1EDD88',
    cyan:    '#0BC4E3',
    red:     '#e53935',
};

Chart.defaults.color           = C.text2;
Chart.defaults.font.family     = "'Barlow Condensed', sans-serif";
Chart.defaults.font.size       = 12;
Chart.defaults.borderColor     = C.border;
Chart.defaults.backgroundColor = C.s2;

const gridOpts = {
    color: C.border,
    drawBorder: false,
};
const tickOpts = { color: C.text2 };

/* ── helpers ─────────────────────────────────────────────────── */
function hexToRgba(hex, a = 1) {
    const r = parseInt(hex.slice(1,3),16),
          g = parseInt(hex.slice(3,5),16),
          b = parseInt(hex.slice(5,7),16);
    return `rgba(${r},${g},${b},${a})`;
}
function makeGradient(ctx, color) {
    const g = ctx.createLinearGradient(0,0,0,400);
    g.addColorStop(0, hexToRgba(color, .8));
    g.addColorStop(1, hexToRgba(color, .2));
    return g;
}

/* ── CHART 1: Top KDA ────────────────────────────────────────── */
(function() {
    const canvas = document.getElementById('chartKDA');
    if (!canvas || !PHP.kdaLabels.length) return;
    const ctx = canvas.getContext('2d');

    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: PHP.kdaLabels,
            datasets: [{
                label: 'KDA',
                data:  PHP.kdaData,
                backgroundColor: PHP.kdaColors.map(c => hexToRgba(c, .75)),
                borderColor:     PHP.kdaColors,
                borderWidth: 1,
                borderRadius: 3,
                borderSkipped: false,
            }]
        },
        options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: C.s2,
                    borderColor: C.border,
                    borderWidth: 1,
                    callbacks: {
                        label: ctx => ` KDA: ${ctx.parsed.x}`,
                        afterLabel: ctx => ` Equipo: ${PHP.kdaEquipos[ctx.dataIndex]}`,
                    }
                }
            },
            scales: {
                x: { grid: gridOpts, ticks: tickOpts, border: { display: false } },
                y: { grid: { display: false }, ticks: { ...tickOpts, font: { size: 13, weight: '700' } }, border: { display: false } },
            }
        }
    });
})();

/* ── CHART 2: Win Rate ───────────────────────────────────────── */
(function() {
    const canvas = document.getElementById('chartWR');
    if (!canvas || !PHP.wrLabels.length) return;
    const ctx = canvas.getContext('2d');

    const colors = PHP.wrLabels.map((_, i) => {
        const v = PHP.wrData[i];
        return v >= 60 ? C.gold : v >= 40 ? C.cyan : C.text3;
    });

    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: PHP.wrLabels,
            datasets: [{
                label: 'Win Rate %',
                data: PHP.wrData,
                backgroundColor: colors.map(c => hexToRgba(c, .6)),
                borderColor: colors,
                borderWidth: 1,
                borderRadius: 3,
                borderSkipped: false,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: C.s2,
                    borderColor: C.border,
                    borderWidth: 1,
                    callbacks: {
                        label: ctx => ` ${ctx.parsed.y}% win rate`,
                        afterLabel: ctx => ` ${PHP.wrPartidos[ctx.dataIndex]} partidos`,
                    }
                }
            },
            scales: {
                x: { grid: { display: false }, ticks: { ...tickOpts, font: { size: 12, weight: '700' } }, border: { display: false } },
                y: {
                    grid: gridOpts,
                    ticks: { ...tickOpts, callback: v => v + '%' },
                    border: { display: false },
                    min: 0, max: 100,
                }
            }
        }
    });
})();

/* ── CHART 3: KDA por rol ────────────────────────────────────── */
(function() {
    const canvas = document.getElementById('chartRolKDA');
    if (!canvas || !PHP.roles.length) return;
    const ctx = canvas.getContext('2d');
    const colores = { Top:'#7eb8f7', Jungle:'#7bc47b', Mid:'#d47bef', ADC:'#f7c47b', Support:'#7bb8d4' };
    const colors = PHP.roles.map(r => colores[r] || C.cyan);

    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: PHP.roles,
            datasets: [{
                data: PHP.rolKDA,
                backgroundColor: colors.map(c => hexToRgba(c, .7)),
                borderColor: colors,
                borderWidth: 1,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '65%',
            plugins: {
                legend: {
                    display: true,
                    position: 'right',
                    labels: { color: C.text2, font: { size: 12, weight: '700' }, padding: 12 }
                },
                tooltip: {
                    backgroundColor: C.s2,
                    borderColor: C.border,
                    borderWidth: 1,
                    callbacks: { label: ctx => ` KDA prom: ${ctx.parsed}` }
                }
            }
        }
    });
})();

/* ── CHART 4: K/D/A por rol ─────────────────────────────────── */
(function() {
    const canvas = document.getElementById('chartRolKDA2');
    if (!canvas || !PHP.roles.length) return;
    const ctx = canvas.getContext('2d');

    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: PHP.roles,
            datasets: [
                {
                    label: 'Kills',
                    data: PHP.rolKills,
                    backgroundColor: hexToRgba(C.gold, .7),
                    borderColor: C.gold,
                    borderWidth: 1,
                    borderRadius: 2,
                },
                {
                    label: 'Deaths',
                    data: PHP.rolDeaths,
                    backgroundColor: hexToRgba(C.red, .5),
                    borderColor: C.red,
                    borderWidth: 1,
                    borderRadius: 2,
                },
                {
                    label: 'Assists',
                    data: PHP.rolAssists,
                    backgroundColor: hexToRgba(C.cyan, .5),
                    borderColor: C.cyan,
                    borderWidth: 1,
                    borderRadius: 2,
                },
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: true,
                    labels: { color: C.text2, font: { size: 11, weight: '700' }, padding: 10, boxWidth: 12 }
                },
                tooltip: { backgroundColor: C.s2, borderColor: C.border, borderWidth: 1 }
            },
            scales: {
                x: { grid: { display: false }, ticks: { ...tickOpts, font: { size: 12, weight: '700' } }, border: { display: false } },
                y: { grid: gridOpts, ticks: tickOpts, border: { display: false } }
            }
        }
    });
})();

/* ── COMPARADOR de jugadores ─────────────────────────────────── */
let chartComparador = null;

async function compararJugadores() {
    const id1 = document.getElementById('jugador1').value;
    const id2 = document.getElementById('jugador2').value;
    if (!id1 || !id2 || id1 === id2) {
        alert('Selecciona dos jugadores distintos.');
        return;
    }

    const url = `assets/api/jugador_stats.php?id1=${id1}&id2=${id2}` + (PHP.splitId ? `&split=${PHP.splitId}` : '');
    let data;
    try {
        const r = await fetch(url);
        data = await r.json();
    } catch(e) {
        console.error(e);
        return;
    }

    document.getElementById('comparador-vacio').style.display = 'none';
    const canvas = document.getElementById('chartComparador');
    if (chartComparador) chartComparador.destroy();
    const ctx = canvas.getContext('2d');

    chartComparador = new Chart(ctx, {
        type: 'radar',
        data: {
            labels: ['KDA', 'Kills/mapa', 'Assists/mapa', 'CS/mapa', 'Win Rate'],
            datasets: [
                {
                    label: data.j1.nickname,
                    data: [data.j1.kda, data.j1.kills, data.j1.assists, data.j1.cs/30, data.j1.wr],
                    backgroundColor: hexToRgba(C.gold, .15),
                    borderColor: C.gold,
                    borderWidth: 2,
                    pointBackgroundColor: C.gold,
                    pointRadius: 4,
                },
                {
                    label: data.j2.nickname,
                    data: [data.j2.kda, data.j2.kills, data.j2.assists, data.j2.cs/30, data.j2.wr],
                    backgroundColor: hexToRgba(C.cyan, .1),
                    borderColor: C.cyan,
                    borderWidth: 2,
                    pointBackgroundColor: C.cyan,
                    pointRadius: 4,
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: true,
                    labels: { color: C.text, font: { size: 13, weight: '700' }, padding: 16 }
                },
                tooltip: { backgroundColor: C.s2, borderColor: C.border, borderWidth: 1 }
            },
            scales: {
                r: {
                    backgroundColor: hexToRgba(C.s1, .5),
                    grid: { color: C.border },
                    angleLines: { color: C.border },
                    ticks: { color: C.text3, backdropColor: 'transparent', font: { size: 10 } },
                    pointLabels: { color: C.text2, font: { size: 12, weight: '700' } },
                }
            }
        }
    });
}
