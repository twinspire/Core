let project = new Project('::projectName::');
project.addAssets('Assets/**');
project.addShaders('Shaders/**');
project.addSources('Sources');
project.addLibrary('twinspire-core');
resolve(project);
