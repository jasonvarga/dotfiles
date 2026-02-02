return {
  {
    name = 'Split',
    cells = {
      { '0,0 12x20',  positions.thirds.left,     '0,0 6x20',  positions.halves.left,  positions.twoThirds.left },
      { '12,0 18x20', positions.twoThirds.right, '6,0 24x20', positions.halves.right, positions.thirds.right },
      { '23,9 6x10',    '23,9 6x10',                 '23,9 6x10',   '23,9 6x10',              '23,9 6x10' },
    },
    apps = {
        Arc = { cell = 1, open = true },
        Code = { cell = 2 },
        PhpStorm = { cell = 2, open = true },
        Tower = { cell = 2 },
        Tinkerwell = { cell = 2 },
        TablePlus = { cell = 2 },
        Ray = { cell = 3 },
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
        Arc = { cell = 2, open = true },
        Code = { cell = 2 },
        PhpStorm = { cell = 2, open = true },
        Tower = { cell = 2 },
        Tinkerwell = { cell = 2 },
        TablePlus = { cell = 2 },
    }
  },
  {
    name = 'Multi',
    cells = {
      { '0,0 5x20',   '0,0 7x20',   '0,8 11x12',  '0,10 11x10', '0,12 11x8' },
      { '5,0 11x20',  '7,0 10x20',  '0,0 11x8',   '0,0 11x10',  '0,0 11x12' },
      { '16,0 14x20', '17,0 13x20', '11,0 19x20', '11,0 19x20', '11,0 19x20' },
    },
    apps = {
        Arc = { cell = 2, open = true },
        Ray = { cell = 1, open = true },
        Code = { cell = 3 },
        PhpStorm = { cell = 3, open = true },
        Tower = { cell = 3 },
        Tinkerwell = { cell = 3 },
        TablePlus = { cell = 3 },
    }
  },
  {
    name = 'Screenshare',
    cells = {
        { positions.center.large }
    },
    apps = {
        Arc = { cell = 1 },
        Code = { cell = 1 },
        PhpStorm = { cell = 1 },
    },
  },
  {
    name = 'Screenshare Split',
    cells = {
        { '10,1 16x18' },
        { '4,1 6x18' },
    },
    apps = {
        Arc = { cell = 1 },
        Code = { cell = 1 },
        PhpStorm = { cell = 1 },
        Ray = { cell = 2 },
    }
  }
}
