package io.github.freshsupasulley.whisperjni;

/**
 * The {@link WhisperContext} enum to configure whisper's sampling strategy
 *
 * @author Miguel Alvarez Díez - Initial contribution
 */
public enum WhisperSamplingStrategy
{
	/**
	 * Similar to OpenAI's GreedyDecoder
	 */
	GREEDY,
	/**
	 * Similar to OpenAI's BeamSearchDecoder
	 */
	BEAM_SEARCH;
}