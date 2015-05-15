ConnectApiHelper
================

`ConnectApiHelper` is an Apex class that makes it easier to do common operations with the classes in the ConnectApi namespace. It includes convenience methods to:

* Post Chatter @-mentions with Apex code.
* Take a feed item or comment body and return an input body that matches it (useful for either editing or re-posting).

Easier @-mentions
-----------------
If you want to mention someone in a post that says: *Hey there @Jane Doe, how are you?*, you can do it in one line like this:

    ConnectApi.FeedItem fi = ConnectApiHelper.postFeedItemWithMentions(Network.getNetworkId(), 'me', 'Hey there {005D00000015tjz}, how are you?');

... instead of this:

    ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
    messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

    ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = 'Hey there ';
    messageInput.messageSegments.add(textSegment);

    ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
    mentionSegment.id = '005D00000015tjz'; // The ID of the user to mention.
    messageInput.messageSegments.add(mentionSegment);

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = ', how are you?';
    messageInput.messageSegments.add(textSegment);

    ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
    input.body = messageInput;
    input.subjectId = 'me';

    ConnectApi.FeedItem fi = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), input, null);

Installation
------------

Just copy the `ConnectApiHelper` and `ConnectApiHelperTest` classes to your Salesforce org. For @-mentions, the methods to use are `ConnectApiHelper.postFeedItemWithMentions` and `ConnectApiHelper.postCommentWithMentions` and the parameters and formatting syntax are described in the method comments. You can also refer to the `ConnectApiHelperTest` class for more examples.

For creating input bodies from output bodies, the methods are `ConnectApiHelper.createFeedItemInputFromBody` and `ConnectApiHelper.createCommentInputFromBody`.

If you need to use API version 31.0 or earlier, be sure to use the ConnectApiHelper class that's contained in the `v31AndEarlier` directory.
