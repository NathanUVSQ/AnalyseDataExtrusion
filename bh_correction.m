function padj = bh_correction(p)
    p = p(:);
    n = numel(p);
    [psort, idx] = sort(p);
    padj_sorted = psort .* n ./ (1:n)';
    padj_sorted = cummin(padj_sorted(end:-1:1));
    padj_sorted = padj_sorted(end:-1:1);
    padj = zeros(size(p));
    padj(idx) = min(padj_sorted,1);
end