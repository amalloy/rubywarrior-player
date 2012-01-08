class Player
  def shoot(dir = :forward)
    @warrior.look(dir).take(3).each do |space|
      if space.unit.kind_of? RubyWarrior::Units::Wizard
        @warrior.shoot!(dir)
        return true
      elsif !space.empty?
        return false
      end
    end
    return false
  end

  def play_turn(warrior)
    hp = warrior.health
    @maxhp ||= hp
    @lasthp = @hp || @maxhp
    @hp = hp
    @warrior = warrior

    if warrior.feel.wall?
      warrior.pivot!
#    if not @captive_rescued
#      smart_move :backward
    elsif warrior.feel.enemy?
      warrior.attack!
    elsif shoot
      # shoot has side effects
    elsif critical and being_attacked
      smart_move(:backward)
    elsif wounded and !being_attacked and @hp < health_needed
      warrior.rest!
    elsif warrior.feel.captive?
      warrior.rescue!
    else
      smart_move
    end
  end

  def smart_move(dir = :forward)
    space = @warrior.feel dir
    if space.wall?
      false
    else
      if space.empty?
        @warrior.walk! dir
      elsif space.enemy?
        @warrior.attack! dir
      elsif space.captive?
        @warrior.rescue! dir
        @captive_rescued = true
      end
      true
    end
  end

  def being_attacked
    @hp < @lasthp
  end

  def wounded
    @hp < @maxhp
  end

  def critical
    @hp < @maxhp / 3
  end

  def health_needed 
    damage = [:backward, :forward].map do |dir|
      @warrior.look(dir)
    end.flatten(1).map do |space|
      damage_budget(space.unit) || 0
    end.reduce :+ 
    damage + 1
  end

  def damage_budget(u) # how much will killing this hurt?
    {
      RubyWarrior::Units::Archer => 9,
      RubyWarrior::Units::Sludge => 6,
      RubyWarrior::Units::ThickSludge => 12
    }[u.class]
  end
end
