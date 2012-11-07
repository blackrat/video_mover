module Meta
  def meta_self
    class << self
      self
    end
  end

  def meta_def name, &blk
    meta.instance_eval { define_method name, &blk }
  end
end