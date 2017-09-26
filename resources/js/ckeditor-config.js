CKEDITOR.editorConfig = function( config ) {
	config.toolbarGroups = [
		{ name: 'document', groups: [ 'mode', 'document', 'doctools' ] },
		{ name: 'clipboard', groups: [ 'clipboard', 'undo' ] },
		{ name: 'editing', groups: [ 'find', 'selection', 'spellchecker', 'editing' ] },
		{ name: 'links', groups: [ 'links' ] },
		{ name: 'insert', groups: [ 'insert' ] },
		{ name: 'forms', groups: [ 'forms' ] },
		{ name: 'tools', groups: [ 'tools' ] },
		{ name: 'styles', groups: [ 'styles' ] },
		{ name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
		{ name: 'others', groups: [ 'others' ] },
		{ name: 'paragraph', groups: [ 'list', 'indent', 'blocks', 'align', 'bidi', 'paragraph' ] },
		{ name: 'colors', groups: [ 'colors' ] },
		{ name: 'about', groups: [ 'about' ] }
	];

  CKEDITOR.stylesSet.add( 'my_styles', [
      // Block-level styles.
      { name: 'Heading', element: 'p', attributes: { 'class': 'heading' } },
      { name: 'Signature',  element: 'p', attributes: { 'class': 'signature' }  }
  ]);
  config.stylesSet = 'my_styles';
  config.allowedContent = true;
  config.contentsCss = '../resources/css/edit.css';
  
	config.removeButtons = 'Subscript,Superscript,Scayt,Link,Unlink,Anchor,Image,Table,HorizontalRule,SpecialChar,Maximize,Strike,NumberedList,BulletedList,Indent,Outdent,Blockquote,About';
	 
  config.extraPlugins = 'autogrow';	
  config.autoGrow_onStartup = true;
  config.autoGrow_maxHeight = 600;  
};
