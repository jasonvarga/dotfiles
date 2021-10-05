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
    }
  },
  {
    name = 'Code and Browser (narrow)',
    description = 'Code 66%, Browser 33%',
    apps = {
      Safari = positions.thirds.left,
      Code = positions.twoThirds.right
    }
  },
  {
    name = 'Code and Ray',
    description = 'Code 83%, Ray 17%',
    apps = {
      Ray = positions.sixths.left,
      Code = positions.fiveSixths.right
    }
  },
  {
    name = 'Code, Ray, Browser',
    description = 'Code 50%, Browser 33%, Ray 17%',
    apps = {
      Ray = positions.sixths.left,
      Code = '5,0 15x20',
      Safari = '20,0 10x20'
    }
  }
}
