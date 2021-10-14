return {
  {
    name = 'Browser',
    description = 'Focused in the center',
    apps = {
      Safari = positions.center.medium,
    }
  },
  {
    name = 'Code',
    description = 'Focused in the center',
    apps = {
      Code = positions.center.medium,
    }
  },
  {
    name = 'Code and Browser',
    description = 'Code 50%, Browser 50%',
    apps = {
      Safari = positions.halves.left,
      Code = positions.halves.right
    },
    toggle = 'Code and Browser (narrow)'
  },
  {
    name = 'Code and Browser (narrow)',
    description = 'Code 66%, Browser 33%',
    apps = {
      Safari = positions.thirds.left,
      Code = positions.twoThirds.right
    },
    toggle = 'Code and Browser'
  },
  {
    name = 'Code and Ray',
    description = 'Code 83%, Ray 17%',
    apps = {
      Ray = positions.sixths.left,
      Code = positions.fiveSixths.right
    },
    toggle = 'Code, Ray, Browser'
  },
  {
    name = 'Code, Ray, Browser',
    description = 'Code 50%, Browser 33%, Ray 17%',
    apps = {
      Safari = '4,0 11x20',
      Code = '15,0 15x20',
      Ray = '0,0 4x20'
    },
    toggle = 'Code and Ray'
  }
}
