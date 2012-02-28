# by redefining the Array class, we're creating/overriding its methods:
class Array
  # acts like Array::each, but in a random order
  def each_random
    if block_given?
      # put the array in a random order
      a = self.shuffle
      
      # iterate over each element, and yield it
      a.each do |i|
        yield i
      end
    else
      # no block was provided, meh
      nil
    end
  end
end
