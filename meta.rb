class Awesome
  def self.method_missing(meth, *args, &block)
    # if we receive a method of the form print_foo, print "foo"
    if meth.to_s =~ /^print_(.+)$/
      puts $1
    else
      # if we don't find what we're looking for, call super
      super
    end
  end
end

Awesome.print_eric
