return {
  {
    name = 'Split',
    cells = {
      { positions.halves.left,  '0,0 12x20',  positions.thirds.left,     '0,0 6x20' },
      { positions.halves.right, '12,0 18x20', positions.twoThirds.right, '6,0 24x20' }
    },
    apps = {
        Safari = { cell = 1, open = true },
        Chrome = { cell = 1 },
        Code = { cell = 2, open = true },
        Tower = { cell = 2 },
        Tinkerwell = { cell = 2 },
    }
  },
  {
    name = 'Narrow',
    cells = {
      { positions.sixths.left, positions.thirds.left },
      { positions.fiveSixths.right, positions.twoThirds.right },
    },
    apps = {
        Ray = { cell = 1, open = true },
        Safari = { cell = 2, open = true },
        Chrome = { cell = 2 },
        Code = { cell = 2, open = true },
        Tower = { cell = 2 },
        Tinkerwell = { cell = 2 },
    }
  },
  {
    name = 'Multi',
    cells = {
      { '0,0 4x20',   '0,8 10x12',               '0,10 10x10',              '0,12 10x8' },
      { '4,0 11x20',  '0,0 10x8',                '0,0 10x10',               '0,0 10x12' },
      { '15,0 15x20', positions.twoThirds.right, positions.twoThirds.right, positions.twoThirds.right },
    },
    apps = {
        Safari = { cell = 2, open = true },
        Ray = { cell = 1, open = true },
        Chrome = { cell = 2 },
        Code = { cell = 3, open = true },
        Tower = { cell = 3 },
        Tinkerwell = { cell = 3 },
    }
  }
}
