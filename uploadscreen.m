#import <Cocoa/Cocoa.h>
int main (int argc, const char * argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	
  if ( argc != 2 ) /* argc should be 2 for correct execution */
  {
    /* We print argv[0] assuming it is the program name */
    printf( "usage: uploadscreen appname \n", argv[0] );
    return 0;
  }
	
	NSString *stringFromArgv = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding]; 
	
	NSArray *windowList = (NSArray*)CGWindowListCopyWindowInfo(kCGWindowListOptionAll | kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
	NSData *data = nil;
		
	for (NSDictionary *entry in windowList) {
		// The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
		// However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
		int sharingState = [[entry objectForKey:(id)kCGWindowSharingState] intValue];
		if(sharingState != kCGWindowSharingNone)
		{
			NSString *appname = [entry objectForKey:(id)kCGWindowOwnerName];
			if ([appname rangeOfString:stringFromArgv].location != NSNotFound ){
				CGWindowID windowID = [[entry objectForKey:(id)kCGWindowNumber] unsignedIntValue];
				
				/* bounds
				 CGRect bounds;
				 CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[entry objectForKey:(id)kCGWindowBounds], &bounds);
				 bounds = CGRectNull;
				 */
				
				/* options
				 uint32_t imageOptions;
				 //imageOptions = kCGWindowImageDefault;
				 //imageOptions = imageOptions | kCGWindowImageBoundsIgnoreFraming;
				 //imageOptions = ChangeBits(imageOptions, kCGWindowImageBoundsIgnoreFraming, [imageFramingEffects intValue] == NSOnState);
				 //imageOptions = ChangeBits(imageOptions, kCGWindowImageShouldBeOpaque, [imageOpaqueImage intValue] == NSOnState);
				 //imageOptions = ChangeBits(imageOptions, kCGWindowImageOnlyShadows, [imageShadowsOnly intValue] == NSOnState);
				 */
				CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, windowID, kCGWindowImageDefault);
				NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:windowImage];
				data = [bitmapRep representationUsingType:NSPNGFileType properties:nil];
				[bitmapRep release];
				CGImageRelease(windowImage);	
				
				break;
			}
		}
	}
	
  [windowList release];
  
	if (!data) {
    printf( "App not found. (example: Terminal)\n");
		return 0;
	}
	 
	// upload image
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.directupload.net/index.php?mode=upload"]];
	[urlRequest setHTTPMethod:@"POST"];
	
	NSString *stringBoundary = @"0xKhTmLbOuNdArY";
  [urlRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary] forHTTPHeaderField:@"Content-Type"];
	
	NSMutableData *postBody = [NSMutableData dataWithCapacity:1];
  
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Disposition: form-data; name=\"bilddatei\"; filename=\"file.png\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:data];
  
  [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Disposition: form-data; name=\"image_link\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Die Bild-URL bitte hier einfügen" dataUsingEncoding:NSUTF8StringEncoding]];
  
  [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Disposition: form-data; name=\"image_comment\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"" dataUsingEncoding:NSUTF8StringEncoding]];
  
  [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Disposition: form-data; name=\"image_tags\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"" dataUsingEncoding:NSUTF8StringEncoding]];
  
  [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Disposition: form-data; name=\"image_mail\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"" dataUsingEncoding:NSUTF8StringEncoding]];
  
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[urlRequest setHTTPBody:postBody];
	
	NSError *error;
  NSData *answer = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:&error];
	
	if (!answer) {
		NSLog(@"Error: %@", [error localizedDescription]);
	} else {
		// grab direct url to image from the HTML response
		NSString *answerString = [NSString stringWithCString:[answer bytes] encoding:NSASCIIStringEncoding];
		NSRange range = [answerString rangeOfString:@"[URL=http://www.directupload.net][IMG]"];
    answerString = [answerString substringFromIndex:range.location+range.length];
    range = [answerString rangeOfString:@"[/IMG][/URL]"];
    NSString *imageUrl = [answerString substringToIndex:range.location];
    
		printf( "%s\n", [imageUrl UTF8String] );
    
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
    [[NSPasteboard generalPasteboard] setString:imageUrl forType:NSPasteboardTypeString];
	}

  [pool drain];
  return 0;
}