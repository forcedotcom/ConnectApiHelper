/*
Copyright (c) 2018, salesforce.com, Inc.
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
 * Helper class that makes it easier to post Chatter @-mentions with Apex code.
 *
 * This class works with API version 31.0 and earlier. There are separate classes
 * that work with a) v32.0 to v34.0, and b) v35.0 and higher.
 *
 * See https://github.com/forcedotcom/ConnectApiHelper for more information.
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
    public static ConnectApi.FeedItem postFeedItemWithMentions(String communityId, String subjectId, String textWithMentions) {

        if (textWithMentions == null || textWithMentions.trim().length() == 0) {
            throw new InvalidParameterException('The textWithMentions parameter must be non-empty.');
        }

        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = getMessageSegmentInputs(textWithMentions);

        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;

        return ConnectApi.ChatterFeeds.postFeedItem(communityId, ConnectApi.FeedType.Record, subjectId, input, null);
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

        return ConnectApi.ChatterFeeds.postComment(communityId, feedItemId, input, null);
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

}
