component {
	this.mappings["/Backbone"] = getParentDirectory(getCurrentTemplatePath());

	private string function getParentDirectory(required path) {
		return GetDirectoryFromPath(
			GetDirectoryFromPath(
				arguments.path
			).ReplaceFirst( "[\\\/]{1}$", "")
		);
	}
}