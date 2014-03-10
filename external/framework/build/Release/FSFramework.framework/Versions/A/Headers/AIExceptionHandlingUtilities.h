#define AI_DURING		id NSExceptionHandlerClass = NSClassFromString(@"NSExceptionHandler"); \
						id	_theExceptionHandler = nil, _theExceptionHandlerDelegate = nil; \
						if (NSExceptionHandlerClass) { \
							typedef id (*DefaultExceptionHandler)(id, SEL, id); \
							DefaultExceptionHandler handlerImp; \
							handlerImp = (DefaultExceptionHandler)[NSExceptionHandlerClass methodForSelector:@selector(defaultExceptionHandler)]; \
							_theExceptionHandler = handlerImp(NSExceptionHandlerClass, @selector(defaultExceptionHandler), nil); \
						} \
						if (_theExceptionHandler) _theExceptionHandlerDelegate = [_theExceptionHandler delegate]; \
						[_theExceptionHandler setDelegate:nil]; \
						NS_DURING
#define AI_HANDLER		NS_HANDLER
#define AI_ENDHANDLER	NS_ENDHANDLER \
						[_theExceptionHandler setDelegate:_theExceptionHandlerDelegate];
