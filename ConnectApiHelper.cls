/*
Copyright (c) 2014, salesforce.com, Inc.
All rights reserved.
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors
      may be used to endorse or promote products derived from this software
      without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 *
 * Helper class that makes it easier to do common operations with the classes in the ConnectApi namespace.
 *
 * Includes convenience methods to:
 *
 *     - Post Chatter @-mentions with Apex code.
 *     - Take a feed item or comment body and return an input body that matches it.
 *       This is useful for when you retrieve a feed item or comment and want to either
 *       re-post or edit it.
 *
 * This class works with API version 32.0 and later. There is a separate class
 * that works with v31.0 and earlier.
 *
 * See https://github.com/alouie-sfdc/ConnectApiHelper for more information.
 *
 */

global class ConnectApiHelper {

    public class InvalidParameterException extends Exception {}

    /**
     * Posts a feed item with @-mentions using an @-mention formatting syntax.
     * 
     * @param communityId Use either the ID of a community, 'internal', or null.
     * @param subjectId The parent of the post. Can be a user ID, a group ID, or a record ID.
     * @param textWithMentions The text of the post. You can @-mention a user or group by using
     *                         the syntax {ID}, for example: 'Hello {005x0000000URNP}, have you
     *                         seen the group {0F9x00000000D7m}?' Links and hashtags will be
     *                         automatically parsed if provided.
     * @return The posted feed item.
     */
    public static ConnectApi.FeedElement postFeedItemWithMentions(String communityId, String subjectId, String textWithMentions) {

        if (textWithMentions == null || textWithMentions.trim().length() == 0) {
            throw new InvalidParameterException('The textWithMentions parameter must be non-empty.');
        }
        
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = getMessageSegmentInputs(textWithMentions);

        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        input.subjectId = subjectId;
        
        return ConnectApi.ChatterFeeds.postFeedElement(communityId, input, null);
    }

    /**
     * Posts a comment with @-mentions using an @-mention formatting syntax.
     * 
     * @param communityId Use either the ID of a community, 'internal', or null.
     * @param feedItemId The ID of the feed item being commented on.
     * @param textWithMentions The text of the comment. You can @-mention a user or group by using
     *                         the syntax {ID}, for example: 'Hello {005x0000000URNP}, have you
     *                         seen the group {0F9x00000000D7m}?' Links and hashtags will be
     *                         automatically parsed if provided.
     * @return The posted comment.
     */
    public static ConnectApi.Comment postCommentWithMentions(String communityId, String feedItemId, String textWithMentions) {

        if (textWithMentions == null || textWithMentions.trim().length() == 0) {
            throw new InvalidParameterException('The textWithMentions parameter must be non-empty.');
        }
        
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = getMessageSegmentInputs(textWithMentions);

        ConnectApi.CommentInput input = new ConnectApi.CommentInput();
        input.body = messageInput;
        
        return ConnectApi.ChatterFeeds.postCommentToFeedElement(communityId, feedItemId, input, null);
    }

    public static List<ConnectApi.MessageSegmentInput> getMessageSegmentInputs(String inputText) {
        if (inputText == null) {
            throw new InvalidParameterException('The inputText parameter cannot be null.');
        }

        List<ConnectApi.MessageSegmentInput> messageSegmentInputs = new List<ConnectApi.MessageSegmentInput>();
        Integer strPos = 0;
        Pattern myPattern = Pattern.compile('\\{[a-zA-Z0-9]{15}\\}|\\{[a-zA-Z0-9]{18}\\}'); // Match a 15 or 18 character ID surrounded by {}.
        Matcher myMatcher = myPattern.matcher(inputText);
        
        while (myMatcher.find()) {
              String textSegment = inputText.substring(strPos, myMatcher.start());
              String mentionId = myMatcher.group();
              // Strip off the { and }.
              mentionId = mentionId.substring(1, mentionId.length() - 1);
              strPos = myMatcher.end();
              
              if (textSegment != null && textSegment.length() > 0) {
                  ConnectApi.TextSegmentInput textSegmentInput = makeTextSegmentInput(textSegment);
                  messageSegmentInputs.add(textSegmentInput);
              }
              
              ConnectApi.MentionSegmentInput mentionSegmentInput = makeMentionSegmentInput(mentionId);
              messageSegmentInputs.add(mentionSegmentInput);
        }

        // Take care of any text that comes after the last mention.
        if (strPos < inputText.length()) {
            String trailingText = inputText.substring(strPos, inputText.length());
            if (trailingText != null && trailingText.length() > 0) {
                ConnectApi.TextSegmentInput textSegmentInput = makeTextSegmentInput(trailingText);
                messageSegmentInputs.add(textSegmentInput);
            }
        }

        return messageSegmentInputs;
    }

    private static ConnectApi.TextSegmentInput makeTextSegmentInput(String text) {
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = text;
        return textSegment;
    }
    
    private static ConnectApi.MentionSegmentInput makeMentionSegmentInput(String mentionId) {
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = mentionId;
        return mentionSegment;
    }
    
    /**
     * Takes an output feed body and returns a message body input that matches it.
     * This is useful for when you retrieve a feed item or comment and want to either re-post or edit it.
     */
    public static ConnectApi.MessageBodyInput createInputFromBody(ConnectApi.FeedBody body) {
        ConnectApi.MessageBodyInput input = new ConnectApi.MessageBodyInput();
        input.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        for (ConnectApi.MessageSegment segment : body.messageSegments) {
            if (segment instanceof ConnectApi.TextSegment) {
                ConnectApi.TextSegment textOutput = (ConnectApi.TextSegment) segment;
                ConnectApi.TextSegmentInput textInput = new ConnectApi.TextSegmentInput();
                textInput.text = textOutput.text;
                input.messageSegments.add(textInput);
            }
            else if (segment instanceof ConnectApi.MentionSegment) {
                ConnectApi.MentionSegment mentionOutput = (ConnectApi.MentionSegment) segment;
                ConnectApi.MentionSegmentInput mentionInput = new ConnectApi.MentionSegmentInput();
                mentionInput.id = mentionOutput.record.id;
                input.messageSegments.add(mentionInput);
            }
            else if (segment instanceof ConnectApi.HashtagSegment) {
                ConnectApi.HashtagSegment hashtagOutput = (ConnectApi.HashtagSegment) segment;
                ConnectApi.HashtagSegmentInput hashtagInput = new ConnectApi.HashtagSegmentInput();
                hashtagInput.tag = hashtagOutput.tag;
                input.messageSegments.add(hashtagInput);
            }
            else if (segment instanceof ConnectApi.LinkSegment) {
                ConnectApi.LinkSegment linkOutput = (ConnectApi.LinkSegment) segment;
                ConnectApi.LinkSegmentInput linkInput = new ConnectApi.LinkSegmentInput();
                linkInput.url = linkOutput.url;
                input.messageSegments.add(linkInput);
            }
            else {
                // The other segment types are system-generated and have no corresponding input types.
            }
            
        }
        return input;
    }
    
    /**
     * Takes an output body and returns a feed item input body that matches it.
     * This is useful for when you retrieve a feed item and want to either re-post or edit it.
     */
    public static ConnectApi.FeedItemInput createFeedItemInputFromBody(ConnectApi.FeedBody body) {
        ConnectApi.MessageBodyInput bodyInput = createInputFromBody(body);
        
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = bodyInput;
        return input;
    }
    
    /**
     * Takes an output body and returns a comment input body that matches it.
     * This is useful for when you retrieve a comment and want to either re-post or edit it.
     */
    public static ConnectApi.CommentInput createCommentInputFromBody(ConnectApi.FeedBody body) {
        ConnectApi.MessageBodyInput bodyInput = createInputFromBody(body);
        
        ConnectApi.CommentInput input = new ConnectApi.CommentInput();
        input.body = bodyInput;
        return input;
    }
        
}
