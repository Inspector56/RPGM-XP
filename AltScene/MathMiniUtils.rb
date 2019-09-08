def abs(x)
  return ( (x > 0) ? x : -x )
end

def floor(x)
  return x.to_i
end

CEIL_CUTOFF = 0.0005
def ceil(x)
  return ( (x > (x.to_i+CEIL_CUTOFF)) ? floor(x+1) : floor(x) )
end

#returns corresponding angle between 0 and 2*PI
def angle_correct(angle)
  while angle < 0 #(2*Math::PI - (abs(angle) % (2*Math::PI)))
    angle += 2*Math::PI
  end
  while angle > 2*Math::PI #(angle % (2*Math::PI))
    angle -= 2*Math::PI
  end
  return angle
end

module Math
  class << self
  
    def distance(a, b)
      return sqrt((a[0]-b[0])**2+(a[1]-b[1])**2)
    end
    
    def min(a, b)
      return ( (a < b) ? a : b )
    end
    
    def max(a, b)
      return ( (a > b) ? a : b )
    end
    
  end
end
