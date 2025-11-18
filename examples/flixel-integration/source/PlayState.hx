package;

import flixel.graphics.FlxGraphic;
import haxe.Json;
import flixel.FlxSprite;
import flixel.FlxG;
import antpak.Pak;
import antpak.integration.FlxPakAssets;
import flixel.FlxState;
import flixel.text.FlxText;

class PlayState extends FlxState
{
	override public function create()
	{
		super.create();

		// Init FlxPakAssets
		// This can be done anywhere, as long as it's done after FlxGame is created.
		FlxPakAssets.init();

		// Mount our pak. We'll hold a reference to it only so we can unmount it later.
		final pak = Pak.mount("./assets.pak", true);

		// Let's play some music.
		// We don't have any assets defined in Project.xml, so the only place
		// this can be pulled from is from our PAK.
		FlxG.sound.playMusic("assets/more/even-more/glitchy.wav", 0.5);

		// Let's read the json from our assets, and create sprites based on the data from it.
		var dogs = Json.parse(FlxG.assets.getText("assets/more/dogs.json"));

		// We need to load the graphic beforehand to determine some positions.
		// Like all other assets, the graphic is pulled from the PAK!
		var graphic = FlxGraphic.fromAssetKey("assets/dog.png");

		var centerX:Float = (FlxG.width - graphic.width) / 2;
		var centerY:Float = (FlxG.height - graphic.height) / 2;

		for (i in 0...dogs.dogs.length)
		{
			var dog:FlxSprite = new FlxSprite().loadGraphic(graphic);
			dog.alpha = (i + 1) * (1 / dogs.dogs.length);
			dog.x = centerX - 25 * i;
			dog.y = centerY;
			add(dog);
		}

		// Finally let's load some text as well
		var text = new FlxText(10, 10, 0, FlxG.assets.getText("assets/more/even-more/cat.txt"));
		add(text);

		// Unmount the pak.
		Pak.unmount(pak);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
