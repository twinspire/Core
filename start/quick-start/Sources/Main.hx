package;

import twinspire.Application;
import kha.Color;

class Main {

	public static function main() {
		Application.noAssetLoading = true;
		Application.create({ title: "::projectName::", width: 1240, height: 768 }, () -> {
			Application.resources.submitLoadRequest(() -> {
				var app = Application.instance;
				::setupScenesInit::

				app.backColor = Color.Black;
				app.initContexts();

				app.start();
			});
		});
	}
}
