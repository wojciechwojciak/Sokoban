require 'gosu'
include Gosu

def get_tile(x, y)
    $tiles[x + y * 13]
end

module Unit
    def x
        return @x / 64
    end
    def y
        return @y / 64
    end
end

class Tile
    attr_reader :tile
    include Unit

    def initialize(x, y, tile)
        @x, @y, @tile = x, y, tile
    end

    def draw
        if @tile == "wall"
            get_tile(7, 6).draw(@x, @y, 1)
        elsif @tile == "floor"
            get_tile(11, 6).draw(@x, @y, 0)
        end
    end
end

class Box
    include Unit

    def initialize(x, y)
        @x, @y = x, y
    end

    def move(dx, dy)
        if (t = $game.get_tile(x + dx, y + dy)).class == Tile or t.class == Box
            return
        end

        @x += dx * 64
        @y += dy *64
        $game.update_objects
        true
    end

    def draw
        get_tile(1, 0).draw(@x, @y, 1)
    end
end

class Player
    include Unit

    def initialize(x, y)
        @x, @y = x, y
    end

    def move(dx, dy)
        if $game.get_tile(x + dx, y + dy).class == Tile
            return
        end
        if (b = $game.get_tile(x + dx, y + dy)).class == Box
            if not b.move(dx, dy)
                return
            end
        end

        @x += dx * 64
        @y += dy *64
    end

    def draw
        get_tile(0, 4).draw(@x, @y, 1)
    end
end

class Goal
    include Unit
    attr_accessor :boxed

    def initialize(x, y)
        @x, @y = x, y
    end

    def draw
        get_tile(12, @boxed ? 4 : 2).draw(@x, @y, 2)
    end
end

class Game < Window
    def initialize
        super(800, 600)
        self.caption = "Ruby Sokoban (R to restart)"
        $tiles = Image.load_tiles("sokoban_tilesheet.png", 64, 64)
        @current_level = 1

        load_level
    end

    def load_level
        @objects = []
        if not File.exists?("level#{@current_level}.txt")
            self.caption = "Ruby Sokoban --- YOU WIN!!!"
            return
        end

        level_data = File.readlines("level#{@current_level}.txt")
        level_data.each_index do |y|
            level_data[y].each_char.each_with_index do |char, x|
                case char
                when "#"
                    @objects << Tile.new(x * 64, y * 64, "wall")
                when "."
                    @objects << Tile.new(x * 64, y * 64, "floor")
                when "X"
                    @objects << Box.new(x * 64, y * 64)
                    @objects << Goal.new(x * 64, y * 64)
                    @objects << Tile.new(x * 64, y * 64, "floor")
                when "o"
                    @objects << Goal.new(x * 64, y * 64)
                    @objects << Tile.new(x * 64, y * 64, "floor")
                when "B"
                    @objects << Box.new(x * 64, y * 64)
                    @objects << Tile.new(x * 64, y * 64, "floor")
                when "P"
                    @objects << @player = Player.new(x * 64, y * 64)
                    @objects << Tile.new(x * 64, y * 64, "floor")
                end
            end
        end
        update_objects
    end

    def update_objects
        unboxed = 0

        @objects.each do |o|
            if o.class == Goal
                unboxed += 1
                if get_tile(o.x, o.y).class == Box
                    unboxed -= 1
                    o.boxed = true
                else
                    o.boxed = false
                end
            end
        end

        if unboxed == 0
            @current_level += 1
            load_level
        end
    end

    def draw
        @objects.each{|o| o.draw}
    end

    def button_down(id)
        @player.move(0, -1) if id == KbUp
        @player.move(0, 1) if id == KbDown
        @player.move(1, 0) if id == KbRight
        @player.move(-1, 0) if id == KbLeft
        load_level if id == KbR
    end

    def get_tile(x, y)
        objects = @objects.reject {|o| o.x != x or o.y != y}
        return (objects.find{|o| o.class == Tile and o.tile == "wall"} or objects.find{|o| o.class == Box})
    end
end

($game = Game.new).show()