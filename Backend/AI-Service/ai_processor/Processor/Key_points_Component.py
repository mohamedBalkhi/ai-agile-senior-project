from abc import ABC, abstractmethod

class KeyPointsStrategy(ABC):
    @abstractmethod
    def extract_key_points(self, summary):
        print("step06: extract key points strategy")
        pass



class BasicKeyPoints(KeyPointsStrategy):
    def extract_key_points(self, summary):
        print("step06: basic key points")
        return ["Basic Key Point 1", "Basic Key Point 2"]



class AdvancedKeyPoints(KeyPointsStrategy):
    def extract_key_points(self, summary):
        print("step06: advanced key points")
        return ["Advanced Key Point 1", "Advanced Key Point 2", "Advanced Key Point 3"]
