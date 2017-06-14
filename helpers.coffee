capitalizeFirst = (s) -> s[0].toUpperCase() + s.slice(1)
capitalize = (s) -> s.split(' ').map(capitalizeFirst).join(' ')
unslugify = (s) -> s.split('_').join(' ')

formatThousands = (n) ->
    np = n - Math.floor n
    ns = Math.floor(n).toString().split('')
    ns.reverse()
    groups = []
    g = ''
    gi = 0
    for n in ns
        if gi > 0 and gi % 3 == 0
            joined = g.split('')
            joined.reverse()
            groups.push joined.join('')
            g = ''
        g += n
        gi += 1
    joined = g.split('')
    joined.reverse()
    groups.push joined.join('')
    groups.reverse()
    return groups.join(',') + np.toFixed(2).slice(1)

module.exports = {
    capitalize
    unslugify
    formatThousands
}