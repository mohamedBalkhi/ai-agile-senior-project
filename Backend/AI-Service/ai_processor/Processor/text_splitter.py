import re

class TextSplitter:
    @staticmethod
    def split_into_sentences(text):

        print("step10: split into sentences!!!!!!!!!!!!!!")
        """
        Split text into sentences and return as array.
        Handles multiple punctuation marks and edge cases.
        """
        # Handle multiple types of sentence endings and clean up spaces
        text = text.replace('\n', ' ').strip()
        # Split the text using // as the delimiter
        sentences = text.split('//')
        print(sentences)
        # Filter out empty strings and strip whitespace
        return [sentence.strip() for sentence in sentences if sentence.strip()] 